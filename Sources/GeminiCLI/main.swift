import ArgumentParser
import Foundation
import GeminiKit

struct GeminiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gemini-cli",
        abstract: "A command-line interface for testing GeminiKit SDK",
        version: "1.0.0",
        subcommands: [
            GenerateCommand.self,
            StreamCommand.self,
            CountCommand.self,
            ChatCommand.self,
            UploadCommand.self,
            ListFilesCommand.self,
            DeleteFileCommand.self,
            GenerateImageCommand.self,
            GenerateVideoCommand.self,
            AnalyzeVideoCommand.self,
            GenerateSpeechCommand.self,
            EmbeddingsCommand.self,
            FunctionCallCommand.self,
            CodeExecutionCommand.self,
            WebGroundingCommand.self,
            OpenAIChatCommand.self,
            ConfigInfoCommand.self
        ]
    )
}

// Run the async command and wait for completion
let semaphore = DispatchSemaphore(value: 0)

Task {
    do {
        await GeminiCLI.main()
        semaphore.signal()
    } catch {
        // Print error to stderr to ensure it's visible
        fputs("Error: \(error.localizedDescription)\n", stderr)
        if let geminiError = error as? GeminiError {
            fputs("Details: \(geminiError)\n", stderr)
        }
        semaphore.signal()
        exit(1)
    }
}

semaphore.wait()
exit(0)