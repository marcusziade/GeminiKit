#if os(Linux)
import Foundation
import FoundationNetworking

/// URLSession-based HTTP client for Linux (simplified for now)
/// Note: This doesn't support true SSE streaming on Linux, but provides basic functionality
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
        // For Linux, we'll simulate streaming by making a regular request
        // and yielding the entire response at once
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (data, response) = try await self.data(for: request)
                    
                    // Check for SSE response
                    if let httpResponse = response as? HTTPURLResponse,
                       let contentType = httpResponse.headers["Content-Type"],
                       contentType.contains("text/event-stream") {
                        // Parse SSE data
                        let text = String(data: data, encoding: .utf8) ?? ""
                        let events = text.split(separator: "\n\n")
                        
                        for event in events {
                            if event.hasPrefix("data: ") {
                                let jsonData = String(event.dropFirst(6))
                                if let data = jsonData.data(using: .utf8) {
                                    continuation.yield(data)
                                }
                            }
                        }
                    } else {
                        // Non-SSE response, yield entire data
                        continuation.yield(data)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func upload(for request: URLRequest, from data: Data) async throws -> (Data, URLResponse) {
        var uploadRequest = request
        uploadRequest.httpBody = data
        return try await self.data(for: uploadRequest)
    }
}

#endif