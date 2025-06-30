import ArgumentParser
import Foundation
import GeminiKit

/// Protocol defining the interface for all CLI commands
protocol CLICommand: AsyncParsableCommand {
    associatedtype Options: CLIOptions
    
    var options: Options { get }
    
    /// Execute the command's main functionality
    func execute(with gemini: GeminiKit) async throws
}

/// Extension providing default implementation
extension CLICommand {
    mutating func run() async throws {
        let gemini = try options.createGeminiKit()
        try await execute(with: gemini)
    }
}

/// Protocol for command options
protocol CLIOptions: ParsableArguments {
    var apiKey: String? { get }
    var model: String { get }
    
    func createGeminiKit() throws -> GeminiKit
    func getModel() throws -> GeminiModel
}

/// Protocol for commands that support output formatting
protocol FormattableCommand {
    var outputFormat: OutputFormat { get }
}

/// Protocol for commands that handle file operations
protocol FileHandlingCommand {
    func validateFile(at path: String) throws -> URL
    func saveOutput(_ data: Data, to path: String) throws
}

/// Protocol for commands that support streaming
protocol StreamableCommand {
    var stream: Bool { get }
    func handleStreamChunk(_ chunk: String)
}

/// Protocol for commands with system instructions
protocol SystemInstructionCommand {
    var systemInstruction: String? { get }
}