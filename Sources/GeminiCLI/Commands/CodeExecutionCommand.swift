import ArgumentParser
import Foundation
import GeminiKit

/// Command for testing code execution
struct CodeExecutionCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "code-execution",
        abstract: "Test code execution"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt that may trigger code execution")
    var prompt: String
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
        let response = try await gemini.generateContent(
            model: model,
            messages: [Content.user(prompt)],
            tools: [.codeExecution]
        )
        
        if let candidate = response.candidates?.first {
            OutputFormatter.printCodeExecutionParts(candidate.content.parts)
        }
    }
}