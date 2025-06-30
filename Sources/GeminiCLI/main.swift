import ArgumentParser
import Foundation
import GeminiKit

struct GeminiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gemini-cli",
        abstract: "A command-line interface for testing GeminiKit SDK",
        discussion: """
        GeminiKit CLI provides access to all Google Gemini API features including:
        - Text generation and streaming
        - Image and video generation
        - Video analysis and transcription
        - Text-to-speech with multiple voices
        - Embeddings generation
        - Function calling and code execution
        - Web search grounding
        - OpenAI-compatible interface
        
        To get started:
          1. Set your API key: export GEMINI_API_KEY="your-key"
          2. Run a command: gemini-cli generate "Hello, world!"
          3. Get help for any command: gemini-cli <command> --help
        
        For detailed documentation, see: https://github.com/marcusziade/GeminiKit
        """,
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