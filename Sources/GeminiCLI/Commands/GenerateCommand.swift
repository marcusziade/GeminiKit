import ArgumentParser
import Foundation
import GeminiKit

/// Command for generating content from a prompt
struct GenerateCommand: CLICommand, FormattableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate content from a prompt",
        discussion: """
        Generate text content using Gemini models with various configuration options.
        
        Examples:
          # Basic generation
          gemini-cli generate "Write a haiku about coding"
          
          # With system instruction and temperature
          gemini-cli generate "Explain quantum computing" \\
            --system "You are a physics professor" \\
            --temperature 0.7
          
          # JSON output with token limit
          gemini-cli generate "List 5 programming languages" \\
            --format json \\
            --max-tokens 200
        """
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt to generate content from")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "System instruction to guide the model's behavior")
    var system: String?
    
    @Option(name: .shortAndLong, help: "Temperature for randomness (0.0-2.0, default: 1.0). Lower values are more focused, higher values more creative")
    var temperature: Double?
    
    @Option(name: .shortAndLong, help: "Maximum number of tokens to generate")
    var maxTokens: Int?
    
    @Option(help: "Output format: text (default), json, or markdown")
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