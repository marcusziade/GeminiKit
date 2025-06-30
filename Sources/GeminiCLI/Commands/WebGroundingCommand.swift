import ArgumentParser
import Foundation
import GeminiKit

/// Command for testing Google Search grounding
struct WebGroundingCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "web-grounding",
        abstract: "Test Google Search grounding"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt that requires web information")
    var prompt: String
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
        let response = try await gemini.generateContent(
            model: model,
            messages: [Content.user(prompt)],
            tools: [.googleSearch]
        )
        
        OutputFormatter.printContent(response)
        OutputFormatter.printGroundingMetadata(response.candidates?.first?.groundingMetadata)
    }
}