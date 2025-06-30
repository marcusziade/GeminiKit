import Foundation

/// The main client for interacting with the Gemini API.
///
/// `GeminiKit` provides a comprehensive Swift interface to Google's Gemini API,
/// supporting all available models and features including text generation,
/// multi-modal inputs, function calling, and media generation.
///
/// ## Topics
///
/// ### Creating a Client
///
/// - ``init(apiKey:configuration:)``
/// - ``init(configuration:)``
/// - ``fromEnvironment()``
///
/// ### Content Generation
///
/// - ``generateContent(model:prompt:systemInstruction:messages:generationConfig:safetySettings:tools:toolConfig:)``
/// - ``streamContent(model:prompt:systemInstruction:messages:generationConfig:safetySettings:tools:toolConfig:)``
/// - ``countTokens(model:prompt:systemInstruction:messages:generationConfig:tools:)``
///
/// ### Chat Sessions
///
/// - ``startChat(model:systemInstruction:history:generationConfig:safetySettings:tools:toolConfig:)``
///
/// ### Media Generation
///
/// - ``generateImages(model:prompt:count:aspectRatio:safetySettings:personGeneration:)``
/// - ``generateVideos(model:prompt:imageReference:duration:aspectRatio:)``
/// - ``generateSpeech(model:text:voice:generationConfig:)``
///
/// ### Advanced Features
///
/// - ``executeWithFunctions(model:messages:functions:functionHandlers:systemInstruction:generationConfig:safetySettings:)``
/// - ``embedContent(model:content:)``
/// - ``batchEmbedContents(model:requests:)``
///
/// ## Example
///
/// ```swift
/// // Create a client
/// let gemini = GeminiKit(apiKey: "your-api-key")
///
/// // Generate content
/// let response = try await gemini.generateContent(
///     model: .gemini25Flash,
///     prompt: "Explain quantum computing"
/// )
///
/// // Start a chat
/// let chat = gemini.startChat(model: .gemini25Pro)
/// let chatResponse = try await chat.sendMessage("Hello!")
/// ```
public final class GeminiKit: @unchecked Sendable {
    internal let configuration: GeminiConfiguration
    internal let apiClient: APIClient
    
    /// Creates a new GeminiKit instance with an API key.
    ///
    /// This is the primary initializer for creating a GeminiKit client.
    /// The API key can be obtained from [Google AI Studio](https://makersuite.google.com/app/apikey).
    ///
    /// - Parameters:
    ///   - apiKey: The API key for authentication
    ///   - configuration: Optional custom configuration. If not provided, default configuration will be used.
    ///
    /// - Note: For production use, consider storing your API key in environment variables
    ///   and using ``fromEnvironment()`` instead.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let gemini = GeminiKit(apiKey: "your-api-key")
    /// ```
    public convenience init(apiKey: String, configuration: GeminiConfiguration? = nil) {
        let config = configuration ?? GeminiConfiguration(apiKey: apiKey)
        self.init(configuration: config)
    }
    
    /// Creates a new GeminiKit instance with a custom configuration.
    ///
    /// Use this initializer when you need fine-grained control over the client behavior,
    /// such as custom timeouts, retry policies, or base URLs.
    ///
    /// - Parameter configuration: The configuration to use
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = GeminiConfiguration(
    ///     apiKey: "your-api-key",
    ///     timeoutInterval: 120,
    ///     maxRetries: 5
    /// )
    /// let gemini = GeminiKit(configuration: config)
    /// ```
    ///
    /// - SeeAlso: ``GeminiConfiguration``
    public init(configuration: GeminiConfiguration) {
        self.configuration = configuration
        self.apiClient = APIClient(configuration: configuration)
    }
    
    /// Creates a new GeminiKit instance from environment variables.
    ///
    /// This method looks for the `GEMINI_API_KEY` environment variable and creates
    /// a client instance if found. This is the recommended approach for production
    /// applications to avoid hardcoding API keys.
    ///
    /// - Returns: A GeminiKit instance if the required environment variables are set, nil otherwise
    ///
    /// ## Required Environment Variables
    ///
    /// - `GEMINI_API_KEY`: Your Gemini API key
    ///
    /// ## Optional Environment Variables
    ///
    /// - `GEMINI_BASE_URL`: Custom API endpoint (defaults to Google's endpoint)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Set environment variable first:
    /// // export GEMINI_API_KEY="your-api-key"
    ///
    /// if let gemini = GeminiKit.fromEnvironment() {
    ///     // Use the client
    /// } else {
    ///     print("GEMINI_API_KEY not set")
    /// }
    /// ```
    public static func fromEnvironment() -> GeminiKit? {
        guard let config = GeminiConfiguration.fromEnvironment() else {
            return nil
        }
        return GeminiKit(configuration: config)
    }
    
    // MARK: - Content Generation
    
    /// Generates content for the given request.
    ///
    /// This is the low-level method for content generation. Most users should prefer
    /// the convenience methods that build the request automatically.
    ///
    /// - Parameters:
    ///   - model: The model to use for generation
    ///   - request: The complete generation request
    /// - Returns: The generated content response
    /// - Throws: ``GeminiError`` if the request fails
    ///
    /// - SeeAlso: ``generateContent(model:prompt:systemInstruction:messages:generationConfig:safetySettings:tools:toolConfig:)``
    public func generateContent(
        model: GeminiModel,
        request: GenerateContentRequest
    ) async throws -> GenerateContentResponse {
        let endpoint = "/models/\(model.rawValue):generateContent"
        return try await apiClient.request(
            endpoint: endpoint,
            body: request
        )
    }
    
    /// Generates content with a simple text prompt
    /// - Parameters:
    ///   - model: The model to use
    ///   - prompt: The text prompt
    ///   - systemInstruction: Optional system instruction
    ///   - config: Optional generation configuration
    /// - Returns: The generated content response
    public func generateContent(
        model: GeminiModel,
        prompt: String,
        systemInstruction: String? = nil,
        config: GenerationConfig? = nil
    ) async throws -> GenerateContentResponse {
        var contents = [Content.user(prompt)]
        
        let request = GenerateContentRequest(
            contents: contents,
            systemInstruction: systemInstruction.map { Content.system($0) },
            generationConfig: config
        )
        
        return try await generateContent(model: model, request: request)
    }
    
    /// Generates content with a conversation history
    /// - Parameters:
    ///   - model: The model to use
    ///   - messages: The conversation messages
    ///   - systemInstruction: Optional system instruction
    ///   - config: Optional generation configuration
    ///   - tools: Optional tools available to the model
    /// - Returns: The generated content response
    public func generateContent(
        model: GeminiModel,
        messages: [Content],
        systemInstruction: String? = nil,
        config: GenerationConfig? = nil,
        tools: [Tool]? = nil
    ) async throws -> GenerateContentResponse {
        let request = GenerateContentRequest(
            contents: messages,
            systemInstruction: systemInstruction.map { Content.system($0) },
            generationConfig: config,
            tools: tools
        )
        
        return try await generateContent(model: model, request: request)
    }
    
    // MARK: - Streaming
    
    /// Streams content generation for the given request
    /// - Parameters:
    ///   - model: The model to use
    ///   - request: The generation request
    /// - Returns: An async stream of generated content responses
    public func streamGenerateContent(
        model: GeminiModel,
        request: GenerateContentRequest
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        let endpoint = "/models/\(model.rawValue):streamGenerateContent"
        return try await apiClient.stream(
            endpoint: endpoint,
            body: request
        )
    }
    
    /// Streams content generation with a simple text prompt
    /// - Parameters:
    ///   - model: The model to use
    ///   - prompt: The text prompt
    ///   - systemInstruction: Optional system instruction
    ///   - config: Optional generation configuration
    /// - Returns: An async stream of generated content responses
    public func streamGenerateContent(
        model: GeminiModel,
        prompt: String,
        systemInstruction: String? = nil,
        config: GenerationConfig? = nil
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        let contents = [Content.user(prompt)]
        
        let request = GenerateContentRequest(
            contents: contents,
            systemInstruction: systemInstruction.map { Content.system($0) },
            generationConfig: config
        )
        
        return try await streamGenerateContent(model: model, request: request)
    }
    
    // MARK: - Token Counting
    
    /// Counts tokens for the given content
    /// - Parameters:
    ///   - model: The model to use
    ///   - request: The count tokens request
    /// - Returns: The token count response
    public func countTokens(
        model: GeminiModel,
        request: CountTokensRequest
    ) async throws -> CountTokensResponse {
        let endpoint = "/models/\(model.rawValue):countTokens"
        return try await apiClient.request(
            endpoint: endpoint,
            body: request
        )
    }
    
    /// Counts tokens for a simple text prompt
    /// - Parameters:
    ///   - model: The model to use
    ///   - prompt: The text prompt
    ///   - systemInstruction: Optional system instruction
    /// - Returns: The token count response
    public func countTokens(
        model: GeminiModel,
        prompt: String,
        systemInstruction: String? = nil
    ) async throws -> CountTokensResponse {
        let contents = [Content.user(prompt)]
        
        let request = CountTokensRequest(
            contents: contents,
            systemInstruction: systemInstruction.map { Content.system($0) }
        )
        
        return try await countTokens(model: model, request: request)
    }
    
    // MARK: - File Management
    
    /// Uploads a file to the API
    /// - Parameters:
    ///   - data: The file data
    ///   - mimeType: The MIME type of the file
    ///   - displayName: The display name for the file
    /// - Returns: The uploaded file information
    public func uploadFile(
        data: Data,
        mimeType: String,
        displayName: String
    ) async throws -> File {
        try await apiClient.uploadFile(
            fileData: data,
            mimeType: mimeType,
            displayName: displayName
        )
    }
    
    /// Uploads a file from a URL
    /// - Parameters:
    ///   - fileURL: The URL of the file to upload
    ///   - displayName: Optional display name (defaults to filename)
    /// - Returns: The uploaded file information
    public func uploadFile(
        from fileURL: URL,
        displayName: String? = nil
    ) async throws -> File {
        let data = try Data(contentsOf: fileURL)
        let mimeType = mimeTypeForURL(fileURL)
        let name = displayName ?? fileURL.lastPathComponent
        
        return try await uploadFile(
            data: data,
            mimeType: mimeType,
            displayName: name
        )
    }
    
    /// Gets information about a file
    /// - Parameter name: The resource name of the file
    /// - Returns: The file information
    public func getFile(name: String) async throws -> File {
        let endpoint = "/\(name)"
        return try await apiClient.request(
            endpoint: endpoint,
            method: "GET",
            body: nil as String?
        )
    }
    
    /// Lists uploaded files
    /// - Parameter pageToken: Optional page token for pagination
    /// - Returns: The list files response
    public func listFiles(pageToken: String? = nil) async throws -> ListFilesResponse {
        var endpoint = "/files"
        if let pageToken = pageToken {
            endpoint += "?pageToken=\(pageToken)"
        }
        
        return try await apiClient.request(
            endpoint: endpoint,
            method: "GET",
            body: nil as String?
        )
    }
    
    /// Deletes a file
    /// - Parameter name: The resource name of the file
    public func deleteFile(name: String) async throws {
        let endpoint = "/\(name)"
        let _: EmptyResponse = try await apiClient.request(
            endpoint: endpoint,
            method: "DELETE",
            body: nil as String?
        )
    }
    
    // MARK: - Helper Methods
    
    private func mimeTypeForURL(_ url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        // Images
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "heic", "heif": return "image/heic"
        
        // Videos
        case "mp4": return "video/mp4"
        case "mpeg": return "video/mpeg"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "flv": return "video/x-flv"
        case "mpg": return "video/mpeg"
        case "webm": return "video/webm"
        case "wmv": return "video/x-ms-wmv"
        case "3gp": return "video/3gpp"
        
        // Audio
        case "wav": return "audio/wav"
        case "mp3": return "audio/mpeg"
        case "aiff": return "audio/aiff"
        case "aac": return "audio/aac"
        case "ogg": return "audio/ogg"
        case "flac": return "audio/flac"
        
        // Documents
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "html", "htm": return "text/html"
        case "css": return "text/css"
        case "js": return "text/javascript"
        case "py": return "text/x-python"
        case "md": return "text/markdown"
        case "csv": return "text/csv"
        case "xml": return "text/xml"
        case "rtf": return "text/rtf"
        
        default: return "application/octet-stream"
        }
    }
}

/// Empty response for void endpoints
private struct EmptyResponse: Codable {}