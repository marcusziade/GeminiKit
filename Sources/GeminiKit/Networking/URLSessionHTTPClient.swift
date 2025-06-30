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
            let task = session.dataTask(with: request)
            
            let delegate = StreamingDelegate(continuation: continuation)
            let delegateSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            
            let streamTask = delegateSession.dataTask(with: request)
            
            continuation.onTermination = { _ in
                streamTask.cancel()
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