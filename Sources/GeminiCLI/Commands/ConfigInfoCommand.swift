import ArgumentParser
import Foundation
import GeminiKit

/// Command for showing configuration and available models
struct ConfigInfoCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "config-info",
        abstract: "Show configuration and available models"
    )
    
    @OptionGroup var options: CommonOptions
    
    func execute(with gemini: GeminiKit) async throws {
        print("Available Models:")
        print("\nText Generation:")
        for model in GeminiModel.allCases {
            if let window = model.contextWindow {
                print("- \(model.rawValue) (context: \(window) tokens)")
            }
        }
        
        print("\nSpecial Capabilities:")
        print("- Thinking: \(GeminiModel.allCases.filter { $0.supportsThinking }.map { $0.rawValue }.joined(separator: ", "))")
        print("- Image Generation: \(GeminiModel.allCases.filter { $0.supportsImageGeneration }.map { $0.rawValue }.joined(separator: ", "))")
        print("- Video Generation: \(GeminiModel.allCases.filter { $0.supportsVideoGeneration }.map { $0.rawValue }.joined(separator: ", "))")
        print("- TTS: \(GeminiModel.allCases.filter { $0.supportsTTS }.map { $0.rawValue }.joined(separator: ", "))")
        
        print("\nVoices:")
        for voice in TTSVoice.allCases.prefix(10) {
            print("- \(voice.rawValue)")
        }
        print("... and \(TTSVoice.allCases.count - 10) more")
    }
}