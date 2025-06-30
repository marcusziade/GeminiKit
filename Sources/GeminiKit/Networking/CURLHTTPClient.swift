#if os(Linux)
import Foundation
import FoundationNetworking

/// cURL-based HTTP client for Linux with true SSE streaming support
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
        // Use process-based cURL for true streaming support on Linux
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Build cURL command
                    let curlCommand = try self.buildCURLCommand(from: request)
                    
                    // Create process
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
                    process.arguments = curlCommand
                    
                    // Create pipe for output
                    let pipe = Pipe()
                    process.standardOutput = pipe
                    process.standardError = pipe
                    
                    // Use an actor for thread-safe finish handling
                    let finishHandler = FinishHandler()
                    
                    // Handle process termination
                    process.terminationHandler = { process in
                        Task {
                            await finishHandler.finish(continuation: continuation, status: process.terminationStatus)
                        }
                    }
                    
                    // Handle stream cancellation
                    continuation.onTermination = { _ in
                        if process.isRunning {
                            process.terminate()
                        }
                    }
                    
                    // Start process
                    try process.run()
                    
                    // Read output incrementally
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = Data()
                    
                    // Read data in chunks
                    while true {
                        let availableData = fileHandle.availableData
                        if availableData.isEmpty {
                            break
                        }
                        
                        buffer.append(availableData)
                        
                        // Parse SSE events from buffer
                        if let text = String(data: buffer, encoding: .utf8) {
                            var remainingText = text
                            
                            // Process complete SSE events (separated by double newlines)
                            while let eventRange = remainingText.range(of: "\n\n") {
                                let eventText = String(remainingText[..<eventRange.lowerBound])
                                remainingText = String(remainingText[eventRange.upperBound...])
                                
                                // Extract data from SSE event
                                var eventData = ""
                                let lines = eventText.split(separator: "\n", omittingEmptySubsequences: false)
                                
                                for line in lines {
                                    if line.hasPrefix("data: ") {
                                        let lineData = String(line.dropFirst(6))
                                        if lineData == "[DONE]" {
                                            // Stream finished
                                            await finishHandler.finish(continuation: continuation, status: 0)
                                            return
                                        }
                                        // SSE can have multiple data lines per event
                                        eventData += lineData
                                    }
                                }
                                
                                // Yield the JSON data
                                if !eventData.isEmpty, let data = eventData.data(using: .utf8) {
                                    continuation.yield(data)
                                }
                            }
                            
                            // Keep remaining partial data in buffer
                            buffer = remainingText.data(using: .utf8) ?? Data()
                            
                            // If no standard SSE events found, try compact format
                            if buffer.count > 0 && remainingText.hasPrefix("data: ") {
                                // Handle compact SSE format where events are back-to-back
                                let chunks = remainingText.components(separatedBy: "data: ").filter { !$0.isEmpty }
                                for chunk in chunks {
                                    let trimmedChunk = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmedChunk == "[DONE]" {
                                        await finishHandler.finish(continuation: continuation, status: 0)
                                        return
                                    }
                                    if let data = trimmedChunk.data(using: .utf8) {
                                        continuation.yield(data)
                                    }
                                }
                                buffer = Data()
                            }
                        }
                    }
                    
                    // Process any remaining data in buffer
                    if !buffer.isEmpty, let text = String(data: buffer, encoding: .utf8) {
                        var eventData = ""
                        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
                        
                        for line in lines {
                            if line.hasPrefix("data: ") {
                                let lineData = String(line.dropFirst(6))
                                if lineData != "[DONE]" {
                                    eventData += lineData
                                }
                            }
                        }
                        
                        if !eventData.isEmpty, let data = eventData.data(using: .utf8) {
                            continuation.yield(data)
                        }
                    }
                    
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
    
    // MARK: - Private Methods
    
    private func buildCURLCommand(from request: URLRequest) throws -> [String] {
        guard let url = request.url else {
            throw GeminiError.invalidRequest("Missing URL")
        }
        
        var args: [String] = []
        
        // Basic options
        args.append("-N") // No buffering for streaming
        args.append("-s") // Silent mode
        args.append("-S") // Show errors
        args.append("-L") // Follow redirects
        
        // Method
        if let method = request.httpMethod {
            args.append("-X")
            args.append(method)
        }
        
        // Headers
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                args.append("-H")
                args.append("\(key): \(value)")
            }
        }
        
        // Body
        if let bodyData = request.httpBody {
            if let bodyString = String(data: bodyData, encoding: .utf8) {
                args.append("-d")
                args.append(bodyString)
            } else {
                // For binary data, we'd need to use a different approach
                throw GeminiError.invalidRequest("Binary request body not supported with cURL streaming")
            }
        }
        
        // URL (must be last)
        args.append(url.absoluteString)
        
        return args
    }
}

// Actor for thread-safe stream finish handling
private actor FinishHandler {
    private var hasFinished = false
    
    func finish(continuation: AsyncThrowingStream<Data, Error>.Continuation, status: Int32) {
        guard !hasFinished else { return }
        hasFinished = true
        
        if status != 0 {
            continuation.finish(throwing: GeminiError.networkError("cURL failed with status: \(status)"))
        } else {
            continuation.finish()
        }
    }
}

#endif