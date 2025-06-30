import ArgumentParser
import Foundation
import GeminiKit

/// Command for generating text embeddings
struct EmbeddingsCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "embeddings",
        abstract: "Generate text embeddings"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The text to embed")
    var text: String
    
    func execute(with gemini: GeminiKit) async throws {
        let response = try await gemini.createEmbeddings(
            EmbeddingsRequest(input: text)
        )
        
        if let embedding = response.data.first {
            print("Embedding dimensions: \(embedding.embedding.count)")
            print("First 10 values: \(embedding.embedding.prefix(10).map { String(format: "%.4f", $0) }.joined(separator: ", "))")
        }
    }
}