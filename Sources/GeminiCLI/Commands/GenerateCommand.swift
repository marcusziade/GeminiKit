import ArgumentParser
import Foundation
import GeminiKit

/// Command for generating content from a prompt
struct GenerateCommand: CLICommand, FormattableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate content from a prompt"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt to generate content from")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "System instruction")
    var system: String?
    
    @Option(name: .shortAndLong, help: "Temperature (0.0-2.0)")
    var temperature: Double?
    
    @Option(name: .shortAndLong, help: "Max output tokens")
    var maxTokens: Int?
    
    @Option(help: "Output format (text/json/markdown)")
    var format: String = "text"
    
    var outputFormat: OutputFormat {
        OutputFormat(rawValue: format) ?? .text
    }
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
        var config = GenerationConfig(
            temperature: temperature,
            maxOutputTokens: maxTokens
        )
        
        if let mimeType = outputFormat.mimeType {
            config = GenerationConfig(
                temperature: config.temperature,
                maxOutputTokens: config.maxOutputTokens,
                responseMimeType: mimeType
            )
        }
        
        let response = try await gemini.generateContent(
            model: model,
            prompt: prompt,
            systemInstruction: system,
            config: config
        )
        
        OutputFormatter.printContent(response)
        OutputFormatter.printUsageMetadata(response.usageMetadata)
    }
}