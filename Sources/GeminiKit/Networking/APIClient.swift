import Foundation
#if os(Linux)
import FoundationNetworking
#endif

/// API client for making requests to the Gemini API
public final class APIClient: @unchecked Sendable {
    private let configuration: GeminiConfiguration
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    /// Creates a new API client
    /// - Parameters:
    ///   - configuration: The API configuration
    ///   - httpClient: The HTTP client to use (defaults to platform-specific implementation)
    public init(configuration: GeminiConfiguration, httpClient: HTTPClient? = nil) {
        self.configuration = configuration
        self.httpClient = httpClient ?? createHTTPClient()
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    /// Performs a JSON request
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - method: The HTTP method
    ///   - body: The request body
    ///   - headers: Additional headers
    ///   - useOpenAI: Whether to use OpenAI compatibility endpoint
    /// - Returns: The decoded response
    public func request<Request: Encodable, Response: Decodable>(
        endpoint: String,
        method: String = "POST",
        body: Request? = nil,
        headers: [String: String] = [:],
        useOpenAI: Bool = false
    ) async throws -> Response {
        let url = buildURL(endpoint: endpoint, useOpenAI: useOpenAI)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Set headers
        let baseHeaders = useOpenAI ? configuration.openAIHeaders : configuration.standardHeaders
        for (key, value) in baseHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw error
            }
        }
        
        // Set timeout
        request.timeoutInterval = configuration.timeoutInterval
        
        // Perform request with retries
        var lastError: Error?
        for attempt in 0..<configuration.maxRetries {
            do {
                let (data, response) = try await httpClient.data(for: request)
                
                
                // Check response
                if let httpResponse = response as? HTTPURLResponse ?? response as? HTTPURLResponse {
                    if httpResponse.statusCode == 429 {
                        throw GeminiError.rateLimitExceeded
                    } else if httpResponse.statusCode >= 400 {
                        // Try to parse error response
                        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                            throw GeminiError.apiError(
                                code: httpResponse.statusCode,
                                message: errorResponse.error.message,
                                details: errorResponse.error.details?.description
                            )
                        } else {
                            throw GeminiError.apiError(
                                code: httpResponse.statusCode,
                                message: "HTTP \(httpResponse.statusCode)",
                                details: String(data: data, encoding: .utf8)
                            )
                        }
                    }
                }
                
                // Decode response
                do {
                    return try decoder.decode(Response.self, from: data)
                } catch {
                    throw error
                }
                
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if case GeminiError.rateLimitExceeded = error {
                    throw error
                }
                if case GeminiError.apiError(let code, _, _) = error, code >= 400 && code < 500 {
                    throw error
                }
                
                // Wait before retry
                if attempt < configuration.maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt)) * 1.0 // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? GeminiError.networkError("Unknown error")
    }
    
    /// Performs a streaming request
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - body: The request body
    ///   - headers: Additional headers
    ///   - useOpenAI: Whether to use OpenAI compatibility endpoint
    /// - Returns: An async stream of decoded responses
    public func stream<Request: Encodable, Response: Decodable>(
        endpoint: String,
        body: Request,
        headers: [String: String] = [:],
        useOpenAI: Bool = false
    ) async throws -> AsyncThrowingStream<Response, Error> {
        let url = buildURL(endpoint: endpoint + "?alt=sse", useOpenAI: useOpenAI)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        let baseHeaders = useOpenAI ? configuration.openAIHeaders : configuration.standardHeaders
        for (key, value) in baseHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body
        request.httpBody = try encoder.encode(body)
        
        // Set timeout
        request.timeoutInterval = configuration.timeoutInterval
        
        // Get stream
        let dataStream = try await httpClient.stream(for: request)
        
        // Transform to response stream
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await data in dataStream {
                        // Parse SSE data
                        if let jsonString = String(data: data, encoding: .utf8) {
                            // Handle SSE format
                            let lines = jsonString.split(separator: "\n")
                            for line in lines {
                                if line.hasPrefix("data: ") {
                                    let jsonData = String(line.dropFirst(6))
                                    if jsonData == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    if let data = jsonData.data(using: .utf8) {
                                        do {
                                            let response = try self.decoder.decode(Response.self, from: data)
                                            continuation.yield(response)
                                        } catch {
                                            // Skip malformed chunks
                                            print("Failed to decode chunk: \(error)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Uploads a file
    /// - Parameters:
    ///   - fileData: The file data to upload
    ///   - mimeType: The MIME type of the file
    ///   - displayName: The display name for the file
    /// - Returns: The uploaded file information
    public func uploadFile(
        fileData: Data,
        mimeType: String,
        displayName: String
    ) async throws -> File {
        // Step 1: Initialize resumable upload
        let initURL = buildURL(endpoint: "/files", useUpload: true)
        var initRequest = URLRequest(url: initURL)
        initRequest.httpMethod = "POST"
        
        // Set headers
        let headers = configuration.uploadHeaders(contentLength: fileData.count, mimeType: mimeType)
        for (key, value) in headers {
            initRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body
        let initBody = ["file": ["display_name": displayName]]
        initRequest.httpBody = try encoder.encode(initBody)
        
        // Perform request
        let (_, response) = try await httpClient.data(for: initRequest)
        
        // Get upload URL from response headers
        guard let httpResponse = response as? HTTPURLResponse,
              let uploadURLString = httpResponse.headers["X-Goog-Upload-URL"],
              let uploadURL = URL(string: uploadURLString) else {
            throw GeminiError.fileError("Failed to get upload URL")
        }
        
        // Step 2: Upload file data
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "PUT"
        
        // Set continuation headers
        let continuationHeaders = configuration.uploadContinuationHeaders(
            uploadURL: uploadURLString,
            offset: 0,
            chunkSize: fileData.count
        )
        for (key, value) in continuationHeaders {
            uploadRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Upload data
        let (responseData, _) = try await httpClient.upload(for: uploadRequest, from: fileData)
        
        // Decode response
        return try decoder.decode(File.self, from: responseData)
    }
    
    private func buildURL(endpoint: String, useOpenAI: Bool = false, useUpload: Bool = false) -> URL {
        let baseURL: URL
        if useUpload {
            baseURL = configuration.uploadBaseURL
        } else if useOpenAI {
            baseURL = configuration.openAIBaseURL
        } else {
            baseURL = configuration.baseURL
        }
        
        // Build the complete URL
        let urlString = baseURL.absoluteString + (baseURL.absoluteString.hasSuffix("/") ? "" : "/") + 
                       (endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint)
        
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL: \(urlString)")
        }
        
        return url
    }
}

/// Error response from the API
struct ErrorResponse: Codable {
    let error: ErrorDetail
}

/// Error detail
struct ErrorDetail: Codable {
    let code: Int?
    let message: String
    let status: String?
    let details: [AnyCodable]?
}