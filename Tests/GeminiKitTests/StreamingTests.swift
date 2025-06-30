import XCTest
import Foundation
#if os(Linux)
import FoundationNetworking
#endif
@testable import GeminiKit

final class StreamingTests: XCTestCase {
    
    func testSSEParsingWithMultipleChunks() async throws {
        // Create a mock HTTP client that simulates multi-chunk SSE responses
        let mockClient = MockHTTPClient()
        
        // On Linux, the HTTP client is expected to parse SSE and yield JSON data
        #if os(Linux)
        let jsonData = """
        {"candidates":[{"content":{"parts":[{"text":"This is a very long response that spans multiple chunks"}],"role":"model"},"finishReason":"STOP","index":0}]}
        """.data(using: .utf8)!
        
        mockClient.streamData = [jsonData]
        #else
        // Simulate SSE chunks that split JSON across boundaries
        let chunk1 = "data: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"This is a "
        let chunk2 = "very long response that spans "
        let chunk3 = "multiple chunks\"}],\"role\":\"model\"},\"finishReason\":\"STOP\",\"index\":0}]}\n\n"
        let chunk4 = "data: [DONE]\n\n"
        
        mockClient.streamData = [
            chunk1.data(using: .utf8)!,
            chunk2.data(using: .utf8)!,
            chunk3.data(using: .utf8)!,
            chunk4.data(using: .utf8)!
        ]
        #endif
        
        // Create API client with mock
        let config = GeminiConfiguration(apiKey: "test-key")
        let apiClient = APIClient(configuration: config, httpClient: mockClient)
        
        // Test streaming
        let request = GenerateContentRequest(
            contents: [Content(role: .user, parts: [.text("Hello")])],
            systemInstruction: nil,
            generationConfig: nil,
            tools: nil,
            toolConfig: nil,
            safetySettings: nil
        )
        
        let stream = try await apiClient.stream(
            endpoint: "models/gemini-pro:streamGenerateContent",
            body: request
        ) as AsyncThrowingStream<GenerateContentResponse, Error>
        
        var responses: [GenerateContentResponse] = []
        for try await response in stream {
            responses.append(response)
        }
        
        XCTAssertEqual(responses.count, 1)
        if !responses.isEmpty,
           case .text(let text) = responses[0].candidates?.first?.content.parts.first {
            XCTAssertEqual(text, "This is a very long response that spans multiple chunks")
        } else if responses.isEmpty {
            XCTFail("No responses received")
        } else {
            XCTFail("Expected text part")
        }
    }
    
    func testSSEParsingWithIncompleteEvent() async throws {
        let mockClient = MockHTTPClient()
        
        // On Linux, the HTTP client is expected to parse SSE and yield JSON data
        #if os(Linux)
        let jsonData = """
        {"candidates":[{"content":{"parts":[{"text":"Complete response"}],"role":"model"},"finishReason":"STOP","index":0}]}
        """.data(using: .utf8)!
        
        mockClient.streamData = [jsonData]
        #else
        // Simulate incomplete event at end of stream
        let chunk1 = "data: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"Complete response\"}],\"role\":\"model\"},\"finishReason\":\"STOP\",\"index\":0}]}\n\n"
        let chunk2 = "data: {\"incomplete\": "  // Incomplete JSON
        
        mockClient.streamData = [
            chunk1.data(using: .utf8)!,
            chunk2.data(using: .utf8)!
        ]
        #endif
        
        let config = GeminiConfiguration(apiKey: "test-key")
        let apiClient = APIClient(configuration: config, httpClient: mockClient)
        
        let request = GenerateContentRequest(
            contents: [Content(role: .user, parts: [.text("Hello")])],
            systemInstruction: nil,
            generationConfig: nil,
            tools: nil,
            toolConfig: nil,
            safetySettings: nil
        )
        
        let stream = try await apiClient.stream(
            endpoint: "models/gemini-pro:streamGenerateContent",
            body: request
        ) as AsyncThrowingStream<GenerateContentResponse, Error>
        
        var responses: [GenerateContentResponse] = []
        for try await response in stream {
            responses.append(response)
        }
        
        // Should only get the complete response, incomplete one is ignored
        XCTAssertEqual(responses.count, 1)
        if !responses.isEmpty,
           case .text(let text) = responses[0].candidates?.first?.content.parts.first {
            XCTAssertEqual(text, "Complete response")
        } else if responses.isEmpty {
            XCTFail("No responses received")
        } else {
            XCTFail("Expected text part")
        }
    }
}

// Mock HTTP client for testing
final class MockHTTPClient: HTTPClient {
    var streamData: [Data] = []
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            headers: [:]
        )
        return (Data(), response)
    }
    
    func stream(for request: URLRequest) async throws -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for data in streamData {
                    continuation.yield(data)
                    // Simulate network delay
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                continuation.finish()
            }
        }
    }
    
    func upload(for request: URLRequest, from data: Data) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            headers: [:]
        )
        return (Data(), response)
    }
}