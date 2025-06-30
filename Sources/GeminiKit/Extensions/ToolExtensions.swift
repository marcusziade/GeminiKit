import Foundation

/// Extensions for working with tools and function calling
extension GeminiKit {
    
    /// Handles function calls in a response
    /// - Parameters:
    ///   - response: The generation response containing function calls
    ///   - functionHandlers: Dictionary mapping function names to handlers
    /// - Returns: Function responses to send back to the model
    public func handleFunctionCalls(
        in response: GenerateContentResponse,
        functionHandlers: [String: (FunctionCall) async throws -> [String: Any]]
    ) async throws -> [Content] {
        var functionResponses: [Content] = []
        
        guard let candidates = response.candidates else { return [] }
        
        for candidate in candidates {
            for part in candidate.content.parts {
                if case .functionCall(let call) = part {
                    guard let handler = functionHandlers[call.name] else {
                        throw GeminiError.invalidRequest("No handler for function: \(call.name)")
                    }
                    
                    let responseData = try await handler(call)
                    let response = FunctionResponse(
                        name: call.name,
                        response: responseData.mapValues { AnyCodable($0) }
                    )
                    
                    functionResponses.append(Content(
                        role: .model,
                        parts: [.functionResponse(response)]
                    ))
                }
            }
        }
        
        return functionResponses
    }
    
    /// Executes a conversation with automatic function calling
    /// - Parameters:
    ///   - model: The model to use
    ///   - messages: Initial messages
    ///   - functions: Function declarations
    ///   - functionHandlers: Handlers for each function
    ///   - systemInstruction: Optional system instruction
    ///   - config: Optional generation configuration
    ///   - maxIterations: Maximum function calling iterations
    /// - Returns: The final response after all function calls
    public func executeWithFunctions(
        model: GeminiModel,
        messages: [Content],
        functions: [FunctionDeclaration],
        functionHandlers: [String: (FunctionCall) async throws -> [String: Any]],
        systemInstruction: String? = nil,
        config: GenerationConfig? = nil,
        maxIterations: Int = 5
    ) async throws -> GenerateContentResponse {
        var conversationHistory = messages
        let tools = [Tool.functionDeclarations(functions)]
        
        for _ in 0..<maxIterations {
            let response = try await generateContent(
                model: model,
                messages: conversationHistory,
                systemInstruction: systemInstruction,
                config: config,
                tools: tools
            )
            
            // Check if response contains function calls
            var hasFunctionCalls = false
            if let candidates = response.candidates {
                for candidate in candidates {
                    for part in candidate.content.parts {
                        if case .functionCall = part {
                            hasFunctionCalls = true
                            break
                        }
                    }
                }
            }
            
            if !hasFunctionCalls {
                // No function calls, return final response
                return response
            }
            
            // Handle function calls
            let functionResponses = try await handleFunctionCalls(
                in: response,
                functionHandlers: functionHandlers
            )
            
            // Add model's response (with function calls) to history
            if let candidate = response.candidates?.first {
                conversationHistory.append(candidate.content)
            }
            
            // Add function responses to history
            conversationHistory.append(contentsOf: functionResponses)
        }
        
        throw GeminiError.invalidResponse("Maximum function calling iterations exceeded")
    }
}

/// Chat extension for function calling
extension Chat {
    
    /// Sends a message with automatic function handling
    /// - Parameters:
    ///   - message: The message to send
    ///   - functionHandlers: Handlers for function calls
    /// - Returns: The model's final response
    @discardableResult
    public func sendMessageWithFunctions(
        _ message: String,
        functionHandlers: [String: (FunctionCall) async throws -> [String: Any]]
    ) async throws -> String {
        // Extract function declarations from tools
        var functions: [FunctionDeclaration] = []
        if let tools = self.tools {
            for tool in tools {
                if case .functionDeclarations(let decls) = tool {
                    functions.append(contentsOf: decls)
                }
            }
        }
        
        let userContent = Content.user(message)
        history.append(userContent)
        
        let response = try await gemini.executeWithFunctions(
            model: model,
            messages: history,
            functions: functions,
            functionHandlers: functionHandlers,
            systemInstruction: systemInstruction,
            config: config
        )
        
        if let candidate = response.candidates?.first,
           let text = extractText(from: candidate.content) {
            history.append(candidate.content)
            return text
        } else {
            throw GeminiError.invalidResponse("No response generated")
        }
    }
    
    private func extractText(from content: Content) -> String? {
        let textParts = content.parts.compactMap { part -> String? in
            if case .text(let text) = part {
                return text
            }
            return nil
        }
        
        return textParts.isEmpty ? nil : textParts.joined(separator: " ")
    }
}

/// Helper for creating common function handlers
public struct FunctionHandlers {
    
    /// Creates a simple calculator function handler
    public static func calculator() -> (String, (FunctionCall) async throws -> [String: Any]) {
        return ("calculate", { call in
            guard let operation = call.args["operation"]?.value as? String,
                  let a = call.args["a"]?.value as? Double,
                  let b = call.args["b"]?.value as? Double else {
                throw GeminiError.invalidRequest("Invalid calculator arguments")
            }
            
            let result: Double
            switch operation {
            case "add": result = a + b
            case "subtract": result = a - b
            case "multiply": result = a * b
            case "divide":
                guard b != 0 else {
                    return ["error": "Division by zero"]
                }
                result = a / b
            default:
                return ["error": "Unknown operation: \(operation)"]
            }
            
            return ["result": result]
        })
    }
    
    /// Creates a weather lookup function handler (mock)
    public static func weather() -> (String, (FunctionCall) async throws -> [String: Any]) {
        return ("get_weather", { call in
            guard let location = call.args["location"]?.value as? String else {
                throw GeminiError.invalidRequest("Location required")
            }
            
            // Mock weather data
            return [
                "location": location,
                "temperature": Int.random(in: 60...85),
                "conditions": ["sunny", "cloudy", "rainy"].randomElement()!,
                "humidity": Int.random(in: 30...70)
            ]
        })
    }
}