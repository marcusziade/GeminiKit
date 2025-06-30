#if !os(Linux)
import Foundation

/// URLSession-based HTTP client for Apple platforms
public final class URLSessionHTTPClient: HTTPClient, @unchecked Sendable {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
    
    public func stream(for request: URLRequest) async throws -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            let delegate = StreamingDelegate(continuation: continuation)
            let delegateSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            delegate.setSession(delegateSession)
            
            let streamTask = delegateSession.dataTask(with: request)
            
            continuation.onTermination = { _ in
                streamTask.cancel()
                delegateSession.invalidateAndCancel()
            }
            
            streamTask.resume()
        }
    }
    
    public func upload(for request: URLRequest, from data: Data) async throws -> (Data, URLResponse) {
        try await session.upload(for: request, from: data)
    }
}

/// URLSession delegate for handling streaming responses
private final class StreamingDelegate: NSObject, URLSessionDataDelegate {
    let continuation: AsyncThrowingStream<Data, Error>.Continuation
    private var errorResponseData = Data()
    private var httpResponse: Foundation.HTTPURLResponse?
    private var session: URLSession?
    
    init(continuation: AsyncThrowingStream<Data, Error>.Continuation) {
        self.continuation = continuation
        super.init()
    }
    
    func setSession(_ session: URLSession) {
        self.session = session
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // If we have an error response, accumulate the data
        if let httpResponse = httpResponse, httpResponse.statusCode >= 400 {
            errorResponseData.append(data)
        } else {
            continuation.yield(data)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation.finish(throwing: error)
        } else if let httpResponse = httpResponse, httpResponse.statusCode >= 400 {
            // Try to parse JSON error response
            if let errorData = errorResponseData.isEmpty ? nil : errorResponseData,
               let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
               let errorInfo = json["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                
                let code = errorInfo["code"] as? Int ?? httpResponse.statusCode
                let status = errorInfo["status"] as? String
                
                // Map to appropriate GeminiError
                let geminiError: GeminiError
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    geminiError = .authenticationFailed(message)
                } else if httpResponse.statusCode == 429 {
                    geminiError = .rateLimitExceeded
                } else if message.contains("quota") {
                    geminiError = .quotaExceeded
                } else if message.contains("model") {
                    geminiError = .invalidModel(message)
                } else {
                    geminiError = .apiError(
                        code: code,
                        message: message,
                        details: status
                    )
                }
                
                continuation.finish(throwing: geminiError)
            } else {
                // Fallback to generic error
                let errorMessage = String(data: errorResponseData, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                let error = GeminiError.apiError(
                    code: httpResponse.statusCode,
                    message: errorMessage,
                    details: nil
                )
                continuation.finish(throwing: error)
            }
        } else {
            continuation.finish()
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // Store the response
        httpResponse = response as? Foundation.HTTPURLResponse
        
        
        // Check if we got an HTTP error response
        if let httpResponse = response as? Foundation.HTTPURLResponse, httpResponse.statusCode >= 400 {
            // Allow the request to continue so we can collect the error body
            completionHandler(.allow)
        } else {
            completionHandler(.allow)
        }
    }
}

#endif