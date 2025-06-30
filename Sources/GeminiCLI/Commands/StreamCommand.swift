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
        
        let stream = try await gemini.streamGenerateContent(
            model: model,
            prompt: prompt,
            systemInstruction: system
        )
        
        var receivedContent = false
        for try await response in stream {
            if let text = response.candidates?.first?.content.parts.first {
                if case .text(let content) = text {
                    handleStreamChunk(content)
                    receivedContent = true
                }
            }
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