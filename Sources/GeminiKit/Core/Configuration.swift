@preconcurrency import Foundation

/// Configuration for the Gemini API client.
///
/// `GeminiConfiguration` provides comprehensive control over API client behavior,
/// including authentication, networking settings, retry policies, and custom headers.
/// Use this to customize timeouts, endpoints, or add proxy support.
///
/// ## Topics
///
/// ### Creating Configuration
///
/// - ``init(apiKey:baseURL:uploadBaseURL:openAIBaseURL:timeoutInterval:maxRetries:customHeaders:useOpenAICompatibility:)``
/// - ``fromEnvironment()``
///
/// ### Configuration Properties
///
/// - ``apiKey``
/// - ``baseURL``
/// - ``uploadBaseURL``
/// - ``openAIBaseURL``
/// - ``timeoutInterval``
/// - ``maxRetries``
/// - ``customHeaders``
/// - ``useOpenAICompatibility``
///
/// ### Headers
///
/// - ``standardHeaders``
/// - ``openAIHeaders``
/// - ``uploadHeaders(contentLength:mimeType:)``
/// - ``uploadContinuationHeaders(uploadURL:offset:chunkSize:)``
///
/// ## Example
///
/// ```swift
/// // Basic configuration
/// let config = GeminiConfiguration(apiKey: "your-api-key")
///
/// // Advanced configuration
/// let customConfig = GeminiConfiguration(
///     apiKey: "your-api-key",
///     timeoutInterval: 120,
///     maxRetries: 5,
///     customHeaders: ["X-Custom-Header": "value"]
/// )
///
/// // From environment variables
/// if let config = GeminiConfiguration.fromEnvironment() {
///     let gemini = GeminiKit(configuration: config)
/// }
/// ```
///
/// ## Environment Variables
///
/// When using ``fromEnvironment()``, the following environment variables are supported:
/// - `GEMINI_API_KEY`: Required. Your Gemini API key
/// - `GEMINI_BASE_URL`: Optional. Custom base URL for API endpoints
///
public struct GeminiConfiguration: Sendable {
    /// The API key for authentication.
    ///
    /// This key is required for all API requests. You can obtain an API key from
    /// [Google AI Studio](https://makersuite.google.com/app/apikey).
    ///
    /// - Important: Never hard-code API keys in your source code. Use environment
    ///   variables or secure key storage solutions.
    public let apiKey: String
    
    /// The base URL for standard API endpoints.
    ///
    /// Defaults to Google's production API endpoint. You can override this for:
    /// - Using a proxy server
    /// - Testing with mock servers
    /// - Accessing regional endpoints
    public let baseURL: URL
    
    /// The base URL for file upload operations.
    ///
    /// File uploads use a separate endpoint optimized for large data transfers.
    /// This URL is used for uploading images, videos, and other media files.
    public let uploadBaseURL: URL
    
    /// The base URL for OpenAI-compatible endpoints.
    ///
    /// When `useOpenAICompatibility` is true, requests are sent to these endpoints
    /// which provide OpenAI API compatibility for easier migration.
    public let openAIBaseURL: URL
    
    /// Request timeout interval in seconds.
    ///
    /// Controls how long to wait for a response before timing out. Default is 60 seconds.
    /// For long-running operations like video generation, consider increasing this value.
    ///
    /// - Note: Streaming responses may require longer timeouts for initial connection.
    public let timeoutInterval: TimeInterval
    
    /// Maximum number of retry attempts for failed requests.
    ///
    /// When a request fails due to network issues or rate limiting, the client will
    /// automatically retry up to this many times with exponential backoff.
    /// Default is 3 attempts.
    ///
    /// - Note: Only certain error types trigger retries (e.g., network errors, 503 errors).
    ///   Authentication errors and client errors (4xx) are not retried.
    public let maxRetries: Int
    
    /// Custom headers to include in all requests.
    ///
    /// Use this to add custom headers for proxy authentication, tracing, or other needs.
    /// These headers are merged with standard headers, with custom headers taking precedence.
    ///
    /// ## Example
    /// ```swift
    /// let config = GeminiConfiguration(
    ///     apiKey: "key",
    ///     customHeaders: [
    ///         "X-Proxy-Authorization": "Bearer token",
    ///         "X-Request-ID": UUID().uuidString
    ///     ]
    /// )
    /// ```
    public let customHeaders: [String: String]
    
    /// Whether to use OpenAI compatibility mode.
    ///
    /// When enabled, the client will use OpenAI-compatible endpoints and request/response
    /// formats. This simplifies migration from OpenAI to Gemini.
    ///
    /// - Note: Not all Gemini features are available in OpenAI compatibility mode.
    public let useOpenAICompatibility: Bool
    
    /// Creates a new configuration with customizable settings.
    ///
    /// Most parameters have sensible defaults, so you typically only need to provide an API key.
    ///
    /// - Parameters:
    ///   - apiKey: Your Gemini API key (required)
    ///   - baseURL: Base URL for API endpoints (defaults to Google's production endpoint)
    ///   - uploadBaseURL: Base URL for file uploads (defaults to Google's upload endpoint)
    ///   - openAIBaseURL: Base URL for OpenAI compatibility (defaults to Google's OpenAI endpoint)
    ///   - timeoutInterval: Request timeout in seconds (defaults to 60)
    ///   - maxRetries: Maximum retry attempts (defaults to 3)
    ///   - customHeaders: Additional headers for all requests (defaults to empty)
    ///   - useOpenAICompatibility: Enable OpenAI compatibility mode (defaults to false)
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
    
    /// Creates a configuration from environment variables.
    ///
    /// This method provides a secure way to configure GeminiKit without hard-coding
    /// sensitive information in your source code. It reads configuration from the
    /// following environment variables:
    ///
    /// - `GEMINI_API_KEY` (required): Your Gemini API key
    /// - `GEMINI_BASE_URL` (optional): Custom base URL for API endpoints
    ///
    /// ## Example
    ///
    /// ```bash
    /// export GEMINI_API_KEY="your-api-key"
    /// export GEMINI_BASE_URL="https://proxy.company.com/gemini"
    /// ```
    ///
    /// ```swift
    /// if let config = GeminiConfiguration.fromEnvironment() {
    ///     let gemini = GeminiKit(configuration: config)
    /// } else {
    ///     print("Error: GEMINI_API_KEY environment variable not set")
    /// }
    /// ```
    ///
    /// - Returns: A configuration instance if the required environment variables are set, nil otherwise
    /// - Note: This is the recommended approach for production applications
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
    
    /// Headers for standard API requests.
    ///
    /// Combines custom headers with required authentication and content-type headers
    /// for standard Gemini API requests. Custom headers take precedence over defaults.
    ///
    /// - Returns: Dictionary of headers including API key authentication
    public var standardHeaders: [String: String] {
        var headers = customHeaders
        headers["x-goog-api-key"] = apiKey
        headers["Content-Type"] = "application/json"
        return headers
    }
    
    /// Headers for OpenAI compatibility requests.
    ///
    /// Provides headers formatted for OpenAI API compatibility mode, using Bearer
    /// token authentication instead of Google's API key header format.
    ///
    /// - Returns: Dictionary of headers with Bearer authentication
    public var openAIHeaders: [String: String] {
        var headers = customHeaders
        headers["Authorization"] = "Bearer \(apiKey)"
        headers["Content-Type"] = "application/json"
        return headers
    }
    
    /// Headers for initiating file upload.
    ///
    /// Creates headers required to start a resumable upload session for large files.
    /// This is the first step in the two-phase upload process for media files.
    ///
    /// - Parameters:
    ///   - contentLength: Total size of the file in bytes
    ///   - mimeType: MIME type of the file (e.g., "image/jpeg", "video/mp4")
    /// - Returns: Dictionary of headers for upload initialization
    ///
    /// ## Supported MIME Types
    /// - Images: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
    /// - Videos: `video/mp4`, `video/mpeg`, `video/mov`, `video/avi`, `video/x-flv`, `video/mpg`, `video/webm`, `video/wmv`, `video/3gpp`
    /// - Audio: `audio/wav`, `audio/mp3`, `audio/aiff`, `audio/aac`, `audio/ogg`, `audio/flac`
    /// - Documents: `application/pdf`
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
    
    /// Headers for continuing a file upload.
    ///
    /// Creates headers for uploading file chunks after the upload session has been initialized.
    /// Supports resumable uploads for reliability with large files.
    ///
    /// - Parameters:
    ///   - uploadURL: The upload URL returned from the initialization request
    ///   - offset: Current byte offset in the file
    ///   - chunkSize: Size of the current chunk being uploaded
    /// - Returns: Dictionary of headers for chunk upload
    ///
    /// - Note: The upload will be finalized automatically when the last chunk is sent
    public func uploadContinuationHeaders(uploadURL: String, offset: Int, chunkSize: Int) -> [String: String] {
        var headers = customHeaders
        headers["Content-Length"] = String(chunkSize)
        headers["X-Goog-Upload-Offset"] = String(offset)
        headers["X-Goog-Upload-Command"] = offset + chunkSize >= chunkSize ? "upload, finalize" : "upload"
        return headers
    }
}