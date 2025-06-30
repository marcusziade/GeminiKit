import Foundation
#if os(Linux)
import FoundationNetworking
#endif

/// Protocol for HTTP client implementations
public protocol HTTPClient: Sendable {
    /// Performs a data request
    /// - Parameters:
    ///   - request: The URL request to perform
    /// - Returns: The response data and URL response
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    
    /// Performs a streaming request
    /// - Parameters:
    ///   - request: The URL request to perform
    /// - Returns: An async stream of data chunks
    func stream(for request: URLRequest) async throws -> AsyncThrowingStream<Data, Error>
    
    /// Uploads data with a request
    /// - Parameters:
    ///   - request: The URL request to perform
    ///   - data: The data to upload
    /// - Returns: The response data and URL response
    func upload(for request: URLRequest, from data: Data) async throws -> (Data, URLResponse)
}

/// HTTP response for non-URLSession implementations
public final class HTTPURLResponse: URLResponse, @unchecked Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    
    public init(url: URL, statusCode: Int, headers: [String: String]) {
        self.statusCode = statusCode
        self.headers = headers
        super.init(url: url, mimeType: nil, expectedContentLength: -1, textEncodingName: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Creates an appropriate HTTP client for the current platform
public func createHTTPClient() -> HTTPClient {
    #if os(Linux)
    return CURLHTTPClient()
    #else
    return URLSessionHTTPClient()
    #endif
}