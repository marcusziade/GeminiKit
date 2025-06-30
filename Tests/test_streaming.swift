#!/usr/bin/env swift

import Foundation

// Simulated SSE response that would come from the server
let sseResponse = """
data: {"candidates":[{"content":{"parts":[{"text":"Server-Sent Events (SSE) is a "}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":"technology enabling servers to push data to web "}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":"clients over HTTP. Unlike WebSockets, SSE is unidirectional"}],"role":"model"},"finishReason":null,"index":0}]}

data: {"candidates":[{"content":{"parts":[{"text":" - data flows only from server to client."}],"role":"model"},"finishReason":"STOP","index":0}]}

data: [DONE]

"""

// Test our SSE parsing logic
func parseSSE(data: String) {
    var buffer = ""
    buffer += data
    
    print("Processing SSE data...")
    print("=" * 50)
    
    var eventCount = 0
    
    // Process complete events (separated by double newlines)
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
                    print("Stream finished")
                    return
                }
                eventData += lineData
            }
        }
        
        // Try to decode the complete event data
        if !eventData.isEmpty {
            eventCount += 1
            print("Event \(eventCount): \(eventData)")
            
            // Try to parse JSON
            if let jsonData = eventData.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    print("  ✓ Valid JSON")
                } catch {
                    print("  ✗ Invalid JSON: \(error)")
                }
            }
            print("")
        }
    }
    
    print("=" * 50)
    print("Processed \(eventCount) events")
}

// Test with chunks split at different points
func testChunkedParsing() {
    print("\nTesting chunked parsing...")
    print("=" * 50)
    
    // Simulate receiving data in chunks
    let chunks = [
        "data: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"This is ",
        "a test of chunked ",
        "SSE parsing\"}],\"role\":\"model\"},\"finishReason\":\"STOP\",\"index\":0}]}\n\n",
        "data: [DONE]\n\n"
    ]
    
    var buffer = ""
    var chunkNum = 0
    
    for chunk in chunks {
        chunkNum += 1
        print("Chunk \(chunkNum): \"\(chunk)\"")
        buffer += chunk
        
        // Process complete events
        while let eventRange = buffer.range(of: "\n\n") {
            let eventText = String(buffer[..<eventRange.lowerBound])
            buffer.removeSubrange(..<eventRange.upperBound)
            
            if eventText.hasPrefix("data: ") {
                let data = String(eventText.dropFirst(6))
                if data == "[DONE]" {
                    print("  → Stream finished")
                } else {
                    print("  → Complete event: \(data)")
                }
            }
        }
        
        if !buffer.isEmpty {
            print("  → Buffer contains incomplete data: \"\(buffer)\"")
        }
    }
}

extension String {
    static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}

// Run tests
parseSSE(data: sseResponse)
testChunkedParsing()