import Foundation

/// A stateful chat session for multi-turn conversations with Gemini models.
///
/// `Chat` maintains conversation history and context across multiple exchanges,
/// making it ideal for building conversational interfaces, chatbots, and interactive
/// assistants. Each message and response is automatically tracked in the session history.
///
/// ## Topics
///
/// ### Creating a Chat Session
///
/// - ``init(gemini:model:systemInstruction:config:tools:history:)``
///
/// ### Sending Messages
///
/// - ``sendMessage(_:)``
/// - ``sendMessageWithContent(_:)``
///
/// ### Streaming Responses
///
/// - ``streamMessage(_:)``
/// - ``streamMessageWithContent(_:)``
///
/// ### Managing History
///
/// - ``messages``
/// - ``clearHistory()``
/// - ``rewindToTurn(_:)``
///
/// ## Example
///
/// ```swift
/// // Create a chat session
/// let chat = gemini.startChat(
///     model: .gemini25Pro,
///     systemInstruction: "You are a helpful coding assistant"
/// )
///
/// // Send messages
/// let response1 = try await chat.sendMessage("What is Swift?")
/// let response2 = try await chat.sendMessage("Show me an example")
///
/// // Stream responses
/// for try await chunk in chat.streamMessage("Explain in detail") {
///     print(chunk, terminator: "")
/// }
///
/// // Access history
/// print("Conversation turns: \(chat.messages.count)")
/// ```
///
/// ## Threading
///
/// Chat sessions are thread-safe and can be used from multiple threads. However,
/// messages are processed sequentially to maintain conversation order.
public final class Chat: @unchecked Sendable {
    internal let gemini: GeminiKit
    internal let model: GeminiModel
    internal var history: [Content]
    internal let systemInstruction: String?
    internal let config: GenerationConfig?
    internal let tools: [Tool]?
    
    /// The complete conversation history.
    ///
    /// Contains all messages exchanged in this chat session, including both user
    /// messages and model responses. Messages are ordered chronologically from
    /// oldest to newest.
    ///
    /// - Note: System instructions are not included in the visible history
    public var messages: [Content] {
        history
    }
    
    /// Creates a new chat session with specified configuration.
    ///
    /// While you can create a chat directly, it's typically easier to use
    /// ``GeminiKit/startChat(model:systemInstruction:history:generationConfig:safetySettings:tools:toolConfig:)``
    /// which handles the setup for you.
    ///
    /// - Parameters:
    ///   - gemini: The GeminiKit instance to use for API calls
    ///   - model: The Gemini model to use for this conversation
    ///   - systemInstruction: Optional instructions that guide the model's behavior throughout the conversation
    ///   - config: Optional generation configuration for response parameters
    ///   - tools: Optional function declarations available to the model
    ///   - history: Optional pre-existing conversation history to continue from
    ///
    /// ## Example
    ///
    /// ```swift
    /// let chat = Chat(
    ///     gemini: geminiClient,
    ///     model: .gemini25Flash,
    ///     systemInstruction: "You are an expert in Swift programming",
    ///     config: GenerationConfig(temperature: 0.7),
    ///     history: previousConversation
    /// )
    /// ```
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
    
    /// Sends a text message and returns the model's response.
    ///
    /// This is the primary method for interacting with the chat session. The message
    /// is added to the conversation history along with the model's response.
    ///
    /// - Parameter message: The text message to send
    /// - Returns: The model's text response
    /// - Throws: ``GeminiError`` if the request fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let response = try await chat.sendMessage("Explain async/await")
    ///     print(response)
    /// } catch {
    ///     print("Chat error: \(error)")
    /// }
    /// ```
    ///
    /// - Note: The response is automatically added to the conversation history
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