import Foundation

// MARK: - OpenAI Compatible Request Models

/// OpenAI-compatible chat completion request
public struct ChatCompletionRequest: Codable, Equatable, Sendable {
    public let model: String
    public let messages: [ChatMessage]
    public let temperature: Double?
    public let maxTokens: Int?
    public let stream: Bool?
    public let tools: [ChatTool]?
    public let toolChoice: String?
    public let reasoningEffort: String?
    public let extraBody: ExtraBody?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream, tools
        case maxTokens = "max_tokens"
        case toolChoice = "tool_choice"
        case reasoningEffort = "reasoning_effort"
        case extraBody = "extra_body"
    }
    
    public init(
        model: String,
        messages: [ChatMessage],
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        stream: Bool? = nil,
        tools: [ChatTool]? = nil,
        toolChoice: String? = nil,
        reasoningEffort: String? = nil,
        extraBody: ExtraBody? = nil
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stream = stream
        self.tools = tools
        self.toolChoice = toolChoice
        self.reasoningEffort = reasoningEffort
        self.extraBody = extraBody
    }
}

/// OpenAI-compatible chat message
public struct ChatMessage: Codable, Equatable, Sendable {
    public let role: String
    public let content: ChatMessageContent
    public let name: String?
    public let toolCalls: [ToolCall]?
    
    enum CodingKeys: String, CodingKey {
        case role, content, name
        case toolCalls = "tool_calls"
    }
    
    public init(role: String, content: String, name: String? = nil) {
        self.role = role
        self.content = .text(content)
        self.name = name
        self.toolCalls = nil
    }
    
    public init(role: String, content: ChatMessageContent, name: String? = nil, toolCalls: [ToolCall]? = nil) {
        self.role = role
        self.content = content
        self.name = name
        self.toolCalls = toolCalls
    }
}

/// Chat message content
public enum ChatMessageContent: Codable, Equatable, Sendable {
    case text(String)
    case parts([ChatContentPart])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let parts = try? container.decode([ChatContentPart].self) {
            self = .parts(parts)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid content type")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(text)
        case .parts(let parts):
            try container.encode(parts)
        }
    }
}

/// Chat content part
public struct ChatContentPart: Codable, Equatable, Sendable {
    public let type: String
    public let text: String?
    public let imageUrl: ImageURL?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
    
    public struct ImageURL: Codable, Equatable, Sendable {
        public let url: String
        public let detail: String?
        
        public init(url: String, detail: String? = nil) {
            self.url = url
            self.detail = detail
        }
    }
    
    public static func text(_ text: String) -> ChatContentPart {
        ChatContentPart(type: "text", text: text, imageUrl: nil)
    }
    
    public static func imageUrl(_ url: String, detail: String? = nil) -> ChatContentPart {
        ChatContentPart(type: "image_url", text: nil, imageUrl: ImageURL(url: url, detail: detail))
    }
}

/// Chat tool
public struct ChatTool: Codable, Equatable, Sendable {
    public let type: String
    public let function: ChatFunction
    
    public init(function: ChatFunction) {
        self.type = "function"
        self.function = function
    }
}

/// Chat function
public struct ChatFunction: Codable, Equatable, Sendable {
    public let name: String
    public let description: String?
    public let parameters: [String: AnyCodable]?
    
    public init(name: String, description: String? = nil, parameters: [String: AnyCodable]? = nil) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

/// Tool call
public struct ToolCall: Codable, Equatable, Sendable {
    public let id: String
    public let type: String
    public let function: FunctionCall
    
    public init(id: String, function: FunctionCall) {
        self.id = id
        self.type = "function"
        self.function = function
    }
}

/// Extra body for Google-specific features
public struct ExtraBody: Codable, Equatable, Sendable {
    public let google: GoogleExtras?
    
    public init(google: GoogleExtras? = nil) {
        self.google = google
    }
}

/// Google-specific extras
public struct GoogleExtras: Codable, Equatable, Sendable {
    public let safetySettings: [SafetySetting]?
    public let thinkingConfig: ThinkingConfig?
    
    enum CodingKeys: String, CodingKey {
        case safetySettings = "safety_settings"
        case thinkingConfig = "thinking_config"
    }
    
    public init(safetySettings: [SafetySetting]? = nil, thinkingConfig: ThinkingConfig? = nil) {
        self.safetySettings = safetySettings
        self.thinkingConfig = thinkingConfig
    }
}

// MARK: - OpenAI Compatible Response Models

/// OpenAI-compatible chat completion response
public struct ChatCompletionResponse: Codable, Equatable, Sendable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [ChatChoice]
    public let usage: Usage?
    
    public init(
        id: String = UUID().uuidString,
        created: Int = Int(Date().timeIntervalSince1970),
        model: String,
        choices: [ChatChoice],
        usage: Usage? = nil
    ) {
        self.id = id
        self.object = "chat.completion"
        self.created = created
        self.model = model
        self.choices = choices
        self.usage = usage
    }
}

/// Chat choice
public struct ChatChoice: Codable, Equatable, Sendable {
    public let index: Int
    public let message: ChatMessage
    public let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
    
    public init(index: Int, message: ChatMessage, finishReason: String? = nil) {
        self.index = index
        self.message = message
        self.finishReason = finishReason
    }
}

/// Usage statistics
public struct Usage: Codable, Equatable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
    
    public init(promptTokens: Int, completionTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = promptTokens + completionTokens
    }
}

/// OpenAI-compatible streaming chunk
public struct ChatCompletionChunk: Codable, Equatable, Sendable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [ChatChunkChoice]
    
    public init(
        id: String = UUID().uuidString,
        created: Int = Int(Date().timeIntervalSince1970),
        model: String,
        choices: [ChatChunkChoice]
    ) {
        self.id = id
        self.object = "chat.completion.chunk"
        self.created = created
        self.model = model
        self.choices = choices
    }
}

/// Chat chunk choice
public struct ChatChunkChoice: Codable, Equatable, Sendable {
    public let index: Int
    public let delta: ChatDelta
    public let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, delta
        case finishReason = "finish_reason"
    }
    
    public init(index: Int, delta: ChatDelta, finishReason: String? = nil) {
        self.index = index
        self.delta = delta
        self.finishReason = finishReason
    }
}

/// Chat delta for streaming
public struct ChatDelta: Codable, Equatable, Sendable {
    public let role: String?
    public let content: String?
    public let toolCalls: [ToolCall]?
    
    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
    }
    
    public init(role: String? = nil, content: String? = nil, toolCalls: [ToolCall]? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
    }
}

// MARK: - Embeddings

/// Embeddings request
public struct EmbeddingsRequest: Codable, Equatable, Sendable {
    public let input: EmbeddingInput
    public let model: String
    public let encodingFormat: String?
    
    enum CodingKeys: String, CodingKey {
        case input, model
        case encodingFormat = "encoding_format"
    }
    
    public init(input: String, model: String = "text-embedding-004", encodingFormat: String? = nil) {
        self.input = .text(input)
        self.model = model
        self.encodingFormat = encodingFormat
    }
    
    public init(input: [String], model: String = "text-embedding-004", encodingFormat: String? = nil) {
        self.input = .array(input)
        self.model = model
        self.encodingFormat = encodingFormat
    }
}

/// Embedding input
public enum EmbeddingInput: Codable, Equatable, Sendable {
    case text(String)
    case array([String])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid input type")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(text)
        case .array(let array):
            try container.encode(array)
        }
    }
}

/// Embeddings response
public struct EmbeddingsResponse: Codable, Equatable, Sendable {
    public let object: String
    public let data: [Embedding]
    public let model: String
    public let usage: EmbeddingUsage
    
    public init(data: [Embedding], model: String, usage: EmbeddingUsage) {
        self.object = "list"
        self.data = data
        self.model = model
        self.usage = usage
    }
}

/// Embedding
public struct Embedding: Codable, Equatable, Sendable {
    public let object: String
    public let embedding: [Double]
    public let index: Int
    
    public init(embedding: [Double], index: Int) {
        self.object = "embedding"
        self.embedding = embedding
        self.index = index
    }
}

/// Embedding usage
public struct EmbeddingUsage: Codable, Equatable, Sendable {
    public let promptTokens: Int
    public let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case totalTokens = "total_tokens"
    }
    
    public init(promptTokens: Int) {
        self.promptTokens = promptTokens
        self.totalTokens = promptTokens
    }
}

// MARK: - Image Generation

/// Image generation request
public struct ImageGenerationRequest: Codable, Equatable, Sendable {
    public let model: String
    public let prompt: String
    public let n: Int?
    public let size: String?
    public let responseFormat: String?
    public let user: String?
    
    enum CodingKeys: String, CodingKey {
        case model, prompt, n, size, user
        case responseFormat = "response_format"
    }
    
    public init(
        model: String,
        prompt: String,
        n: Int? = nil,
        size: String? = nil,
        responseFormat: String? = nil,
        user: String? = nil
    ) {
        self.model = model
        self.prompt = prompt
        self.n = n
        self.size = size
        self.responseFormat = responseFormat
        self.user = user
    }
}

/// Image generation response
public struct ImageGenerationResponse: Codable, Equatable, Sendable {
    public let created: Int
    public let data: [ImageData]
    
    public struct ImageData: Codable, Equatable, Sendable {
        public let url: String?
        public let b64Json: String?
        public let revisedPrompt: String?
        
        enum CodingKeys: String, CodingKey {
            case url
            case b64Json = "b64_json"
            case revisedPrompt = "revised_prompt"
        }
    }
}