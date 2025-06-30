import Foundation

/// A chat session for conversational interactions
public final class Chat: @unchecked Sendable {
    internal let gemini: GeminiKit
    internal let model: GeminiModel
    internal var history: [Content]
    internal let systemInstruction: String?
    internal let config: GenerationConfig?
    internal let tools: [Tool]?
    
    /// The conversation history
    public var messages: [Content] {
        history
    }
    
    /// Creates a new chat session
    /// - Parameters:
    ///   - gemini: The GeminiKit instance
    ///   - model: The model to use
    ///   - systemInstruction: Optional system instruction
    ///   - config: Optional generation configuration
    ///   - tools: Optional tools available to the model
    ///   - history: Optional initial conversation history
    public init(
        gemini: GeminiKit,
        model: GeminiModel,
        systemInstruction: String? = nil,
        config: GenerationConfig? = nil,
        tools: [Tool]? = nil,
        history: [Content] = []
    ) {
        self.gemini = gemini
        self.model = model
        self.systemInstruction = systemInstruction
        self.config = config
        self.tools = tools
        self.history = history
    }
    
    /// Sends a message and gets a response
    /// - Parameter message: The message to send
    /// - Returns: The model's response
    @discardableResult
    public func sendMessage(_ message: String) async throws -> String {
        let userContent = Content.user(message)
        history.append(userContent)
        
        let response = try await gemini.generateContent(
            model: model,
            messages: history,
            systemInstruction: systemInstruction,
            config: config,
            tools: tools
        )
        
        if let candidate = response.candidates?.first,
           let text = extractText(from: candidate.content) {
            history.append(candidate.content)
            return text
        } else {
            throw GeminiError.invalidResponse("No response generated")
        }
    }
    
    /// Sends a message with parts and gets a response
    /// - Parameter parts: The parts to send
    /// - Returns: The model's response content
    @discardableResult
    public func sendMessage(parts: [Part]) async throws -> Content {
        let userContent = Content(role: .user, parts: parts)
        history.append(userContent)
        
        let response = try await gemini.generateContent(
            model: model,
            messages: history,
            systemInstruction: systemInstruction,
            config: config,
            tools: tools
        )
        
        if let candidate = response.candidates?.first {
            history.append(candidate.content)
            return candidate.content
        } else {
            throw GeminiError.invalidResponse("No response generated")
        }
    }
    
    /// Streams a message and gets streaming responses
    /// - Parameter message: The message to send
    /// - Returns: An async stream of response chunks
    public func streamMessage(_ message: String) async throws -> AsyncThrowingStream<String, Error> {
        let userContent = Content.user(message)
        history.append(userContent)
        
        let responseStream = try await gemini.streamGenerateContent(
            model: model,
            request: GenerateContentRequest(
                contents: history,
                systemInstruction: systemInstruction.map { Content.system($0) },
                generationConfig: config,
                tools: tools
            )
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                var fullResponseParts: [Part] = []
                
                do {
                    for try await response in responseStream {
                        if let candidate = response.candidates?.first,
                           let text = extractText(from: candidate.content) {
                            // Accumulate the full response
                            fullResponseParts.append(contentsOf: candidate.content.parts)
                            continuation.yield(text)
                        }
                    }
                    
                    // Add the complete response to history
                    if !fullResponseParts.isEmpty {
                        history.append(Content(role: .model, parts: fullResponseParts))
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Counts tokens for the current conversation
    /// - Returns: The token count
    public func countTokens() async throws -> Int {
        let response = try await gemini.countTokens(
            model: model,
            request: CountTokensRequest(
                contents: history,
                systemInstruction: systemInstruction.map { Content.system($0) },
                tools: tools
            )
        )
        
        return response.totalTokens
    }
    
    /// Clears the conversation history
    public func clearHistory() {
        history.removeAll()
    }
    
    /// Adds a message to the history without sending it
    /// - Parameter content: The content to add
    public func addToHistory(_ content: Content) {
        history.append(content)
    }
    
    /// Removes the last message from history
    /// - Returns: The removed message, if any
    @discardableResult
    public func removeLastMessage() -> Content? {
        guard !history.isEmpty else { return nil }
        return history.removeLast()
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

// MARK: - GeminiKit Chat Extension

extension GeminiKit {
    /// Creates a new chat session
    /// - Parameters:
    ///   - model: The model to use
    ///   - systemInstruction: Optional system instruction
    ///   - config: Optional generation configuration
    ///   - tools: Optional tools available to the model
    ///   - history: Optional initial conversation history
    /// - Returns: A new chat session
    public func startChat(
        model: GeminiModel,
        systemInstruction: String? = nil,
        config: GenerationConfig? = nil,
        tools: [Tool]? = nil,
        history: [Content] = []
    ) -> Chat {
        Chat(
            gemini: self,
            model: model,
            systemInstruction: systemInstruction,
            config: config,
            tools: tools,
            history: history
        )
    }
}