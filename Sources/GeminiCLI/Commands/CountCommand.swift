import ArgumentParser
import Foundation
import GeminiKit

/// Command for counting tokens in text
struct CountCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "count",
        abstract: "Count tokens in text"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The text to count tokens for")
    var text: String
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
        let response = try await gemini.countTokens(
            model: model,
            prompt: text
        )
        
        print("Total tokens: \(response.totalTokens)")
    }
}