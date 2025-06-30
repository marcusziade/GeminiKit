import ArgumentParser
import Foundation
import GeminiKit

/// Command for generating speech from text
struct GenerateSpeechCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-speech",
        abstract: "Generate speech from text"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The text to convert to speech")
    var text: String
    
    @Option(name: .shortAndLong, help: "Voice name")
    var voice: String = "Zephyr"
    
    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "speech.wav"
    
    func execute(with gemini: GeminiKit) async throws {
        guard let ttsVoice = TTSVoice(rawValue: voice) else {
            throw GeminiError.invalidRequest("Invalid voice: \(voice). Use 'config-info' command to see available voices.")
        }
        
        print("Generating speech...")
        
        let audioData = try await gemini.generateSpeech(
            text: text,
            voice: ttsVoice
        )
        
        let outputURL = URL(fileURLWithPath: output)
        try gemini.saveAudioToFile(audioData, outputURL: outputURL)
        
        print("Audio saved to: \(outputURL.path)")
    }
}