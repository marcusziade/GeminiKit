import ArgumentParser
import Foundation
import GeminiKit

/// Command for OpenAI-compatible chat completion
struct OpenAIChatCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "openai-chat",
        abstract: "Test OpenAI-compatible chat completion"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The user message")
    var message: String
    
    @Option(name: .shortAndLong, help: "System message")
    var system: String?
    
    @Flag(help: "Stream the response")
    var stream = false
    
    func execute(with gemini: GeminiKit) async throws {
        var messages: [ChatMessage] = []
        
        if let system = system {
            messages.append(ChatMessage(role: "system", content: system))
        }
        
        messages.append(ChatMessage(role: "user", content: message))
        
        let request = ChatCompletionRequest(
            model: options.model,
            messages: messages,
            stream: stream
        )
        
        if stream {
            let stream = try await gemini.streamChatCompletion(request)
            
            for try await chunk in stream {
                if let delta = chunk.choices.first?.delta.content {
                    print(delta, terminator: "")
                    fflush(stdout)
                }
            }
            print()
        } else {
            let response = try await gemini.createChatCompletion(request)
            
            if let content = response.choices.first?.message.content {
                if case .text(let text) = content {
                    print(text)
                }
            }
            
            if let usage = response.usage {
                print("\n---")
                print("Tokens - Prompt: \(usage.promptTokens), Completion: \(usage.completionTokens), Total: \(usage.totalTokens)")
            }
        }
    }
}