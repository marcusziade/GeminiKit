import Foundation

/// OpenAI compatibility extension for GeminiKit
extension GeminiKit {
    
    /// Creates a chat completion using OpenAI-compatible API
    /// - Parameter request: The chat completion request
    /// - Returns: The chat completion response
    public func createChatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        // Convert OpenAI request to Gemini format
        let contents = try convertChatMessages(request.messages)
        
        var generationConfig = GenerationConfig(
            temperature: request.temperature,
            maxOutputTokens: request.maxTokens
        )
        
        // Handle reasoning effort
        if let reasoningEffort = request.reasoningEffort {
            let thinkingBudget: Int
            switch reasoningEffort {
            case "none": thinkingBudget = 0
            case "low": thinkingBudget = 8192
            case "medium": thinkingBudget = 16384
            case "high": thinkingBudget = 32768
            default: thinkingBudget = -1
            }
            generationConfig = GenerationConfig(
                temperature: generationConfig.temperature,
                maxOutputTokens: generationConfig.maxOutputTokens,
                thinkingConfig: ThinkingConfig(thinkingBudget: thinkingBudget)
            )
        }
        
        // Handle extra body
        var safetySettings: [SafetySetting]?
        if let google = request.extraBody?.google {
            safetySettings = google.safetySettings
            if let thinkingConfig = google.thinkingConfig {
                generationConfig = GenerationConfig(
                    temperature: generationConfig.temperature,
                    maxOutputTokens: generationConfig.maxOutputTokens,
                    thinkingConfig: thinkingConfig
                )
            }
        }
        
        // Convert tools
        let tools = try request.tools?.map { tool in
            Tool.functionDeclarations([FunctionDeclaration(
                name: tool.function.name,
                description: tool.function.description ?? "",
                parameters: FunctionParameters(
                    properties: convertParameters(tool.function.parameters),
                    required: extractRequired(tool.function.parameters)
                )
            )])
        }
        
        let geminiRequest = GenerateContentRequest(
            contents: contents,
            generationConfig: generationConfig,
            tools: tools,
            safetySettings: safetySettings
        )
        
        let model = try geminiModelFromString(request.model)
        let response = try await generateContent(model: model, request: geminiRequest)
        
        return convertToOpenAIResponse(response, model: request.model)
    }
    
    /// Streams a chat completion using OpenAI-compatible API
    /// - Parameter request: The chat completion request
    /// - Returns: An async stream of chat completion chunks
    public func streamChatCompletion(_ request: ChatCompletionRequest) async throws -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        // Convert request similar to createChatCompletion
        let contents = try convertChatMessages(request.messages)
        
        var generationConfig = GenerationConfig(
            temperature: request.temperature,
            maxOutputTokens: request.maxTokens
        )
        
        if let reasoningEffort = request.reasoningEffort {
            let thinkingBudget: Int
            switch reasoningEffort {
            case "none": thinkingBudget = 0
            case "low": thinkingBudget = 8192
            case "medium": thinkingBudget = 16384
            case "high": thinkingBudget = 32768
            default: thinkingBudget = -1
            }
            generationConfig = GenerationConfig(
                temperature: generationConfig.temperature,
                maxOutputTokens: generationConfig.maxOutputTokens,
                thinkingConfig: ThinkingConfig(thinkingBudget: thinkingBudget)
            )
        }
        
        let geminiRequest = GenerateContentRequest(
            contents: contents,
            generationConfig: generationConfig
        )
        
        let model = try geminiModelFromString(request.model)
        let stream = try await streamGenerateContent(model: model, request: geminiRequest)
        
        let requestId = UUID().uuidString
        let created = Int(Date().timeIntervalSince1970)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await response in stream {
                        if let candidate = response.candidates?.first {
                            let chunk = convertToOpenAIChunk(
                                candidate: candidate,
                                id: requestId,
                                created: created,
                                model: request.model
                            )
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Creates embeddings using OpenAI-compatible API
    /// - Parameter request: The embeddings request
    /// - Returns: The embeddings response
    public func createEmbeddings(_ request: EmbeddingsRequest) async throws -> EmbeddingsResponse {
        let texts: [String]
        switch request.input {
        case .text(let text):
            texts = [text]
        case .array(let array):
            texts = array
        }
        
        var embeddings: [Embedding] = []
        var totalTokens = 0
        
        for (index, text) in texts.enumerated() {
            let geminiRequest = GenerateContentRequest(
                contents: [Content.user(text)]
            )
            
            struct EmbedRequest: Codable {
                let content: Content
            }
            
            struct EmbedResponse: Codable {
                let embedding: EmbeddingValues?
            }
            
            struct EmbeddingValues: Codable {
                let values: [Double]
            }
            
            let embedRequest = EmbedRequest(content: geminiRequest.contents.first!)
            let response: EmbedResponse = try await apiClient.request(
                endpoint: "/models/\(request.model):embedContent",
                body: embedRequest
            )
            
            if let values = response.embedding?.values {
                embeddings.append(Embedding(embedding: values, index: index))
            }
            
            // Estimate tokens (rough approximation)
            totalTokens += text.count / 4
        }
        
        return EmbeddingsResponse(
            data: embeddings,
            model: request.model,
            usage: EmbeddingUsage(promptTokens: totalTokens)
        )
    }
    
    /// Creates images using OpenAI-compatible API
    /// - Parameter request: The image generation request
    /// - Returns: The image generation response
    public func createImages(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        let model = try geminiModelFromString(request.model)
        
        let config = GenerationConfig(
            candidateCount: request.n ?? 1,
            responseModalities: [.image]
        )
        
        let geminiRequest = GenerateContentRequest(
            contents: [Content.user(request.prompt)],
            generationConfig: config
        )
        
        let response = try await generateContent(model: model, request: geminiRequest)
        
        var imageData: [ImageGenerationResponse.ImageData] = []
        
        if let candidates = response.candidates {
            for candidate in candidates {
                for part in candidate.content.parts {
                    if case .inlineData(let data) = part,
                       data.mimeType.starts(with: "image/") {
                        if request.responseFormat == "b64_json" {
                            imageData.append(.init(url: nil, b64Json: data.data, revisedPrompt: nil))
                        } else {
                            // Convert to data URL
                            let url = "data:\(data.mimeType);base64,\(data.data)"
                            imageData.append(.init(url: url, b64Json: nil, revisedPrompt: nil))
                        }
                    }
                }
            }
        }
        
        return ImageGenerationResponse(
            created: Int(Date().timeIntervalSince1970),
            data: imageData
        )
    }
    
    // MARK: - Helper Methods
    
    private func convertChatMessages(_ messages: [ChatMessage]) throws -> [Content] {
        return try messages.map { message in
            let role: Role
            switch message.role {
            case "system": role = .system
            case "user": role = .user
            case "assistant": role = .model
            default: throw GeminiError.invalidRequest("Unknown role: \(message.role)")
            }
            
            var parts: [Part] = []
            
            switch message.content {
            case .text(let text):
                parts.append(.text(text))
            case .parts(let contentParts):
                for part in contentParts {
                    if let text = part.text {
                        parts.append(.text(text))
                    } else if let imageUrl = part.imageUrl {
                        if imageUrl.url.starts(with: "data:") {
                            // Parse data URL
                            let components = imageUrl.url.split(separator: ",", maxSplits: 1)
                            if components.count == 2 {
                                let header = String(components[0])
                                if header.hasPrefix("data:"),
                                   let semicolonIndex = header.firstIndex(of: ";") {
                                    let mimeType = String(header[header.index(header.startIndex, offsetBy: 5)..<semicolonIndex])
                                    let base64Data = String(components[1])
                                    parts.append(.inlineData(InlineData(mimeType: mimeType, data: base64Data)))
                                }
                            }
                        } else {
                            throw GeminiError.invalidRequest("URL images not supported, use base64")
                        }
                    }
                }
            }
            
            // Add tool calls if present
            if let toolCalls = message.toolCalls {
                for toolCall in toolCalls {
                    parts.append(.functionCall(FunctionCall(
                        name: toolCall.function.name,
                        args: toolCall.function.args
                    )))
                }
            }
            
            return Content(role: role, parts: parts)
        }
    }
    
    private func convertToOpenAIResponse(_ response: GenerateContentResponse, model: String) -> ChatCompletionResponse {
        var choices: [ChatChoice] = []
        
        if let candidates = response.candidates {
            for (index, candidate) in candidates.enumerated() {
                let message = convertContentToMessage(candidate.content)
                let finishReason = convertFinishReason(candidate.finishReason)
                choices.append(ChatChoice(index: index, message: message, finishReason: finishReason))
            }
        }
        
        var usage: Usage?
        if let metadata = response.usageMetadata {
            usage = Usage(
                promptTokens: metadata.promptTokenCount,
                completionTokens: metadata.candidatesTokenCount ?? 0
            )
        }
        
        return ChatCompletionResponse(
            model: model,
            choices: choices,
            usage: usage
        )
    }
    
    private func convertToOpenAIChunk(candidate: Candidate, id: String, created: Int, model: String) -> ChatCompletionChunk {
        var content: String?
        var toolCalls: [ToolCall]?
        
        for part in candidate.content.parts {
            switch part {
            case .text(let text):
                content = text
            case .functionCall(let call):
                let toolCall = ToolCall(
                    id: "call_" + UUID().uuidString,
                    function: call
                )
                toolCalls = [toolCall]
            default:
                break
            }
        }
        
        let delta = ChatDelta(
            role: candidate.index == 0 ? "assistant" : nil,
            content: content,
            toolCalls: toolCalls
        )
        
        let finishReason = convertFinishReason(candidate.finishReason)
        
        return ChatCompletionChunk(
            id: id,
            created: created,
            model: model,
            choices: [ChatChunkChoice(index: 0, delta: delta, finishReason: finishReason)]
        )
    }
    
    private func convertContentToMessage(_ content: Content) -> ChatMessage {
        let role = content.role == .model ? "assistant" : content.role.rawValue
        
        var text = ""
        var toolCalls: [ToolCall] = []
        
        for part in content.parts {
            switch part {
            case .text(let t):
                text += t
            case .functionCall(let call):
                let toolCall = ToolCall(
                    id: "call_" + UUID().uuidString,
                    function: call
                )
                toolCalls.append(toolCall)
            default:
                break
            }
        }
        
        return ChatMessage(
            role: role,
            content: .text(text),
            toolCalls: toolCalls.isEmpty ? nil : toolCalls
        )
    }
    
    private func convertFinishReason(_ reason: FinishReason?) -> String? {
        guard let reason = reason else { return nil }
        
        switch reason {
        case .stop: return "stop"
        case .maxTokens: return "length"
        case .safety: return "content_filter"
        case .recitation: return "content_filter"
        default: return "stop"
        }
    }
    
    private func geminiModelFromString(_ model: String) throws -> GeminiModel {
        guard let geminiModel = GeminiModel(rawValue: model) else {
            throw GeminiError.invalidRequest("Unknown model: \(model)")
        }
        return geminiModel
    }
    
    private func convertParameters(_ params: [String: AnyCodable]?) -> [String: ParameterProperty] {
        guard let params = params,
              let properties = params["properties"] as? [String: Any] else {
            return [:]
        }
        
        var result: [String: ParameterProperty] = [:]
        
        for (key, value) in properties {
            if let prop = value as? [String: Any],
               let type = prop["type"] as? String {
                let description = prop["description"] as? String
                
                switch type {
                case "string":
                    result[key] = .string(description: description, enum: prop["enum"] as? [String])
                case "number":
                    result[key] = .number(description: description)
                case "integer":
                    result[key] = .integer(description: description)
                case "boolean":
                    result[key] = .boolean(description: description)
                case "array":
                    if let itemsType = prop["items"] as? [String: Any],
                       let itemType = itemsType["type"] as? String {
                        let itemProperty: ParameterProperty
                        switch itemType {
                        case "string": itemProperty = .string(description: nil, enum: nil)
                        case "number": itemProperty = .number(description: nil)
                        case "integer": itemProperty = .integer(description: nil)
                        case "boolean": itemProperty = .boolean(description: nil)
                        default: itemProperty = .string(description: nil, enum: nil)
                        }
                        result[key] = .array(description: description, items: itemProperty)
                    }
                default:
                    result[key] = .string(description: description, enum: nil)
                }
            }
        }
        
        return result
    }
    
    private func extractRequired(_ params: [String: AnyCodable]?) -> [String]? {
        guard let params = params,
              let required = params["required"] as? [String] else {
            return nil
        }
        return required
    }
}