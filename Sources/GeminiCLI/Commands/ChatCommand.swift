import ArgumentParser
import Foundation
import GeminiKit

/// Command for interactive chat sessions
struct ChatCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Interactive chat session"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Option(name: .shortAndLong, help: "System instruction")
    var system: String?
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
        let chat = gemini.startChat(
            model: model,
            systemInstruction: system
        )
        
        print("Chat session started. Type 'exit' to quit.")
        print("---")
        
        while true {
            print("\nYou: ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }
            
            if input.lowercased() == "exit" {
                print("Goodbye!")
                break
            }
            
            print("\nAssistant: ", terminator: "")
            
            do {
                let stream = try await chat.streamMessage(input)
                for try await chunk in stream {
                    print(chunk, terminator: "")
                    fflush(stdout)
                }
                print("\n---")
            } catch let error as GeminiError {
                print("\n❌ Error: \(error.errorDescription ?? "Unknown error")")
                if let suggestion = error.recoverySuggestion {
                    print("💡 \(suggestion)")
                }
                print("---")
            }
        }
    }
}