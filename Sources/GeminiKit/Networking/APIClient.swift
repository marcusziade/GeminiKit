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
                    switch httpResponse.statusCode {
                    case 200...299:
                        // Success
                        break
                    case 401:
                        throw GeminiError.authenticationFailed("Invalid or expired API key")
                    case 403:
                        throw GeminiError.authenticationFailed("API key lacks required permissions")
                    case 404:
                        if endpoint.contains("/models/") {
                            let modelName = endpoint.split(separator: "/").last.map(String.init) ?? "unknown"
                            throw GeminiError.modelNotFound(modelName)
                        } else {
                            throw GeminiError.invalidRequest("Endpoint not found: \(endpoint)")
                        }
                    case 429:
                        throw GeminiError.rateLimitExceeded
                    case 503:
                        throw GeminiError.networkError("Service temporarily unavailable")
                    default:
                        // Try to parse error response
                        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                            // Check for specific error types
                            if errorResponse.error.message.contains("quota") {
                                throw GeminiError.quotaExceeded
                            } else if errorResponse.error.message.contains("model") {
                                throw GeminiError.invalidModel(errorResponse.error.message)
                            } else {
                                throw GeminiError.apiError(
                                    code: httpResponse.statusCode,
                                    message: errorResponse.error.message,
                                    details: errorResponse.error.details?.description
                                )
                            }
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
        
        // Transform to response stream with proper SSE parsing
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    #if os(Linux)
                    // On Linux, CURLHTTPClient already parses SSE and yields JSON data
                    for try await data in dataStream {
                        do {
                            let response = try self.decoder.decode(Response.self, from: data)
                            continuation.yield(response)
                        } catch {
                            // Try to decode as error response
                            if let errorResponse = try? self.decoder.decode(ErrorResponse.self, from: data) {
                                let geminiError = GeminiError.apiError(
                                    code: errorResponse.error.code ?? 0,
                                    message: errorResponse.error.message,
                                    details: errorResponse.error.details?.description
                                )
                                continuation.finish(throwing: geminiError)
                                return
                            }
                            // Skip malformed chunks silently
                        }
                    }
                    #else
                    // For non-Linux platforms, we need to parse SSE format
                    var buffer = ""
                    
                    for try await data in dataStream {
                        // Append new data to buffer
                        guard let text = String(data: data, encoding: .utf8) else {
                            continue
                        }
                        buffer += text
                        
                        
                        // Process events as they arrive - look for complete JSON objects
                        while let dataStart = buffer.range(of: "data: "),
                              let jsonStart = buffer.range(of: "{", range: dataStart.upperBound..<buffer.endIndex),
                              let jsonEnd = self.findMatchingBrace(in: buffer, startingAt: jsonStart.lowerBound) {
                            
                            // Extract the complete JSON object
                            let jsonData = String(buffer[jsonStart.lowerBound...jsonEnd])
                            
                            // Remove processed data from buffer
                            buffer.removeSubrange(buffer.startIndex...jsonEnd)
                            
                            // Skip any trailing whitespace or newlines
                            while !buffer.isEmpty && (buffer.first == "\n" || buffer.first == " ") {
                                buffer.removeFirst()
                            }
                            
                            if let data = jsonData.data(using: .utf8) {
                                do {
                                    let response = try self.decoder.decode(Response.self, from: data)
                                    continuation.yield(response)
                                } catch {
                                    // Skip malformed JSON
                                }
                            }
                        }
                        
                        // Process complete events - handle both standard SSE (with \n\n) and compact format
                        // First try standard SSE format
                        while let eventRange = buffer.range(of: "\n\n") {
                            let eventText = String(buffer[..<eventRange.lowerBound])
                            buffer.removeSubrange(..<eventRange.upperBound)
                            
                            // Process the complete event
                            var eventData = ""
                            let lines = eventText.split(separator: "\n", omittingEmptySubsequences: false)
                            
                            for line in lines {
                                if line.hasPrefix("data: ") {
                                    let lineData = String(line.dropFirst(6))
                                    if lineData == "[DONE]" {
                                        // Stream finished
                                        continuation.finish()
                                        return
                                    }
                                    // SSE can have multiple data lines per event
                                    eventData += lineData
                                }
                            }
                            
                            // Try to decode the complete event data
                            if !eventData.isEmpty, let jsonBytes = eventData.data(using: .utf8) {
                                do {
                                    let response = try self.decoder.decode(Response.self, from: jsonBytes)
                                    continuation.yield(response)
                                } catch {
                                    // Try to decode as error response
                                    if let errorResponse = try? self.decoder.decode(ErrorResponse.self, from: jsonBytes) {
                                        let geminiError = GeminiError.apiError(
                                            code: errorResponse.error.code ?? 0,
                                            message: errorResponse.error.message,
                                            details: errorResponse.error.details?.description
                                        )
                                        continuation.finish(throwing: geminiError)
                                        return
                                    }
                                    // Skip malformed events silently
                                }
                            }
                        }
                    }
                    
                    
                    // Process any remaining data in buffer as a final event
                    if !buffer.isEmpty && buffer.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        // Process the remaining buffer as if it were a complete event
                        var eventData = ""
                        let lines = buffer.split(separator: "\n", omittingEmptySubsequences: false)
                        
                        for line in lines {
                            if line.hasPrefix("data: ") {
                                let lineData = String(line.dropFirst(6))
                                if lineData != "[DONE]" {
                                    eventData += lineData
                                }
                            }
                        }
                        
                        // Try to decode the remaining event data
                        if !eventData.isEmpty, let jsonBytes = eventData.data(using: .utf8) {
                            do {
                                let response = try self.decoder.decode(Response.self, from: jsonBytes)
                                continuation.yield(response)
                            } catch {
                                // Try to decode as error response
                                if let errorResponse = try? self.decoder.decode(ErrorResponse.self, from: jsonBytes) {
                                    let geminiError = GeminiError.apiError(
                                        code: errorResponse.error.code ?? 0,
                                        message: errorResponse.error.message,
                                        details: errorResponse.error.details?.description
                                    )
                                    continuation.finish(throwing: geminiError)
                                    return
                                }
                                // Skip malformed final event silently
                            }
                        }
                    }
                    #endif
                    
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
        var uploadURLString: String?
        
        #if os(Linux)
        if let httpResponse = response as? HTTPURLResponse {
            uploadURLString = httpResponse.headers["X-Goog-Upload-URL"]
        }
        #else
        if let httpResponse = response as? Foundation.HTTPURLResponse {
            if let headers = httpResponse.allHeaderFields as? [String: String] {
                uploadURLString = headers["X-Goog-Upload-URL"]
            }
        }
        #endif
        
        guard let urlString = uploadURLString,
              let uploadURL = URL(string: urlString) else {
            throw GeminiError.fileError("Failed to get upload URL")
        }
        
        // Step 2: Upload file data
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "PUT"
        
        // Set continuation headers
        let continuationHeaders = configuration.uploadContinuationHeaders(
            uploadURL: urlString,
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
    
    private func findMatchingBrace(in string: String, startingAt start: String.Index) -> String.Index? {
        var depth = 0
        var inString = false
        var escaped = false
        var index = start
        
        while index < string.endIndex {
            let char = string[index]
            
            if !escaped {
                if char == "\"" && !inString {
                    inString = true
                } else if char == "\"" && inString {
                    inString = false
                } else if !inString {
                    if char == "{" {
                        depth += 1
                    } else if char == "}" {
                        depth -= 1
                        if depth == 0 {
                            return index
                        }
                    }
                }
                
                escaped = (char == "\\")
            } else {
                escaped = false
            }
            
            index = string.index(after: index)
        }
        
        return nil
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