import Foundation
import GeminiKit

/// Example showing how to use streaming responses with GeminiKit
@main
struct StreamingExample {
    static func main() async {
        do {
            // Initialize Gemini client
            guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
                print("Error: GEMINI_API_KEY environment variable not set")
                return
            }
            
            let gemini = Gemini(apiKey: apiKey)
            
            // Create a conversation with streaming enabled
            let conversation = gemini.startConversation()
            
            print("Asking for a long response to test streaming...")
            print("=" * 50)
            
            // Request a long response that will be streamed in chunks
            let stream = try await conversation.stream(
                "Write a detailed explanation of how server-sent events (SSE) work, " +
                "including examples and implementation details. Make this response long " +
                "enough to span multiple chunks."
            )
            
            print("Streaming response:")
            print("-" * 50)
            
            // Process the stream
            var fullResponse = ""
            var chunkCount = 0
            
            for try await chunk in stream {
                chunkCount += 1
                if let text = chunk.candidates?.first?.content.parts.first?.text {
                    print("Chunk \(chunkCount): \(text.prefix(50))...")
                    fullResponse += text
                }
            }
            
            print("-" * 50)
            print("Received \(chunkCount) chunks")
            print("Total response length: \(fullResponse.count) characters")
            
        } catch {
            print("Error: \(error)")
        }
    }
}

extension String {
    static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}