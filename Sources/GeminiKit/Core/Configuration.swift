import Foundation

/// Configuration for the Gemini API client
public struct GeminiConfiguration: Sendable {
    /// The API key for authentication
    public let apiKey: String
    
    /// The base URL for the API
    public let baseURL: URL
    
    /// The base URL for file uploads
    public let uploadBaseURL: URL
    
    /// The base URL for OpenAI compatibility endpoints
    public let openAIBaseURL: URL
    
    /// Request timeout interval
    public let timeoutInterval: TimeInterval
    
    /// Maximum retry attempts
    public let maxRetries: Int
    
    /// Custom headers to include in requests
    public let customHeaders: [String: String]
    
    /// Whether to use OpenAI compatibility mode
    public let useOpenAICompatibility: Bool
    
    /// Creates a new configuration
    /// - Parameters:
    ///   - apiKey: The API key for authentication
    ///   - baseURL: The base URL for the API (defaults to production)
    ///   - uploadBaseURL: The base URL for file uploads (defaults to production)
    ///   - openAIBaseURL: The base URL for OpenAI compatibility endpoints (defaults to production)
    ///   - timeoutInterval: Request timeout interval (defaults to 60 seconds)
    ///   - maxRetries: Maximum retry attempts (defaults to 3)
    ///   - customHeaders: Custom headers to include in requests
    ///   - useOpenAICompatibility: Whether to use OpenAI compatibility mode
    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!,
        uploadBaseURL: URL = URL(string: "https://generativelanguage.googleapis.com/upload/v1beta")!,
        openAIBaseURL: URL = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai")!,
        timeoutInterval: TimeInterval = 60,
        maxRetries: Int = 3,
        customHeaders: [String: String] = [:],
        useOpenAICompatibility: Bool = false
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.uploadBaseURL = uploadBaseURL
        self.openAIBaseURL = openAIBaseURL
        self.timeoutInterval = timeoutInterval
        self.maxRetries = maxRetries
        self.customHeaders = customHeaders
        self.useOpenAICompatibility = useOpenAICompatibility
    }
    
    /// Creates a configuration from environment variables
    /// - Returns: A configuration if the required environment variables are set
    public static func fromEnvironment() -> GeminiConfiguration? {
        guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
            return nil
        }
        
        var config = GeminiConfiguration(apiKey: apiKey)
        
        if let baseURL = ProcessInfo.processInfo.environment["GEMINI_BASE_URL"],
           let url = URL(string: baseURL) {
            config = GeminiConfiguration(
                apiKey: apiKey,
                baseURL: url,
                uploadBaseURL: config.uploadBaseURL,
                openAIBaseURL: config.openAIBaseURL,
                timeoutInterval: config.timeoutInterval,
                maxRetries: config.maxRetries,
                customHeaders: config.customHeaders,
                useOpenAICompatibility: config.useOpenAICompatibility
            )
        }
        
        return config
    }
    
    /// Headers for standard API requests
    public var standardHeaders: [String: String] {
        var headers = customHeaders
        headers["x-goog-api-key"] = apiKey
        headers["Content-Type"] = "application/json"
        return headers
    }
    
    /// Headers for OpenAI compatibility requests
    public var openAIHeaders: [String: String] {
        var headers = customHeaders
        headers["Authorization"] = "Bearer \(apiKey)"
        headers["Content-Type"] = "application/json"
        return headers
    }
    
    /// Headers for file upload initialization
    public func uploadHeaders(contentLength: Int, mimeType: String) -> [String: String] {
        var headers = customHeaders
        headers["x-goog-api-key"] = apiKey
        headers["X-Goog-Upload-Protocol"] = "resumable"
        headers["X-Goog-Upload-Command"] = "start"
        headers["X-Goog-Upload-Header-Content-Length"] = String(contentLength)
        headers["X-Goog-Upload-Header-Content-Type"] = mimeType
        headers["Content-Type"] = "application/json"
        return headers
    }
    
    /// Headers for file upload continuation
    public func uploadContinuationHeaders(uploadURL: String, offset: Int, chunkSize: Int) -> [String: String] {
        var headers = customHeaders
        headers["Content-Length"] = String(chunkSize)
        headers["X-Goog-Upload-Offset"] = String(offset)
        headers["X-Goog-Upload-Command"] = offset + chunkSize >= chunkSize ? "upload, finalize" : "upload"
        return headers
    }
}