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

// Use Task to run async code on Linux
Task {
    await GeminiCLI.main()
    exit(0)
}
RunLoop.main.run()