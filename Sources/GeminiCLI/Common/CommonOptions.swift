import ArgumentParser
import Foundation
import GeminiKit

/// Common options shared across all CLI commands
struct CommonOptions: CLIOptions {
    @Option(name: .shortAndLong, help: "API key (defaults to GEMINI_API_KEY env var)")
    var apiKey: String?
    
    @Option(help: "Model to use")
    var model: String = "gemini-2.5-flash"
    
    func createGeminiKit() throws -> GeminiKit {
        guard let key = apiKey ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
            throw GeminiError.invalidAPIKey
        }
        return GeminiKit(apiKey: key)
    }
    
    func getModel() throws -> GeminiModel {
        guard let geminiModel = GeminiModel(rawValue: model) else {
            throw GeminiError.invalidModel(model)
        }
        return geminiModel
    }
}