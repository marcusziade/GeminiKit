#if os(Linux)
import Foundation
import FoundationNetworking

/// URLSession-based HTTP client for Linux with SSE streaming support
public final class CURLHTTPClient: HTTPClient, @unchecked Sendable {
    private let session: URLSession
    
    public init() {
        self.session = URLSession.shared
    }
    
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: GeminiError.networkError("No data received"))
                }
            }
            task.resume()
        }
    }
    
    public func stream(for request: URLRequest) async throws -> AsyncThrowingStream<Data, Error> {
        // Linux implementation using URLSession with delegate for streaming
        AsyncThrowingStream { continuation in
            let delegate = StreamingDelegate(continuation: continuation)
            let delegateSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            
            let task = delegateSession.dataTask(with: request)
            
            continuation.onTermination = { _ in
                task.cancel()
                delegateSession.invalidateAndCancel()
            }
            
            task.resume()
        }
    }
    
    public func upload(for request: URLRequest, from data: Data) async throws -> (Data, URLResponse) {
        var uploadRequest = request
        uploadRequest.httpBody = data
        return try await self.data(for: uploadRequest)
    }
}

/// URLSession delegate for handling streaming responses on Linux
private final class StreamingDelegate: NSObject, URLSessionDataDelegate {
    let continuation: AsyncThrowingStream<Data, Error>.Continuation
    
    init(continuation: AsyncThrowingStream<Data, Error>.Continuation) {
        self.continuation = continuation
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        continuation.yield(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation.finish(throwing: error)
        } else {
            continuation.finish()
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
}

#endif