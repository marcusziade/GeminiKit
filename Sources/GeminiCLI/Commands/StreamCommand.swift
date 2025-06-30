import ArgumentParser
import Foundation
import GeminiKit

/// Command for streaming content generation
struct StreamCommand: CLICommand, StreamableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Stream content generation"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt to generate content from")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "System instruction")
    var system: String?
    
    var stream: Bool { true }
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
        let stream: AsyncThrowingStream<GenerateContentResponse, Error>
        do {
            stream = try await gemini.streamGenerateContent(
                model: model,
                prompt: prompt,
                systemInstruction: system
            )
        } catch {
            throw error
        }
        
        var receivedContent = false
        var responseCount = 0
        var lastContent = ""
        
        do {
            for try await response in stream {
                responseCount += 1
                
                if let text = response.candidates?.first?.content.parts.first {
                    if case .text(let content) = text {
                        // Only print the new content (delta)
                        if content.hasPrefix(lastContent) {
                            let newContent = String(content.dropFirst(lastContent.count))
                            handleStreamChunk(newContent)
                            lastContent = content
                        } else {
                            // Full content if not incremental
                            handleStreamChunk(content)
                            lastContent = content
                        }
                        receivedContent = true
                    }
                }
            }
        } catch {
            throw error
        }
        
        if receivedContent {
            print()
        }
    }
    
    func handleStreamChunk(_ chunk: String) {
        print(chunk, terminator: "")
        fflush(stdout)
    }
}