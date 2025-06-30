import ArgumentParser
import Foundation
import GeminiKit

/// Command for generating images from text
struct GenerateImageCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-image",
        abstract: "Generate images from text"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt for image generation")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "Number of images (1-4)")
    var count: Int = 1
    
    @Option(name: .shortAndLong, help: "Aspect ratio (1:1, 3:4, 4:3, 9:16, 16:9)")
    var ratio: String = "1:1"
    
    @Option(name: .shortAndLong, help: "Output directory")
    var output: String = "."
    
    @Option(help: "Negative prompt")
    var negative: String?
    
    func execute(with gemini: GeminiKit) async throws {
        guard count >= 1 && count <= 4 else {
            throw GeminiError.invalidRequest("Image count must be between 1 and 4")
        }
        
        let aspectRatio = ImageAspectRatio(rawValue: ratio) ?? .square
        let outputDir = URL(fileURLWithPath: output)
        
        // Verify output directory exists
        if !FileManager.default.fileExists(atPath: outputDir.path) {
            throw GeminiError.fileError("Output directory does not exist: \(output)")
        }
        
        print("Generating \(count) image(s)...")
        
        let urls = try await gemini.generateImageFiles(
            model: .imagen30Generate002,
            prompt: prompt,
            outputDirectory: outputDir,
            count: count,
            aspectRatio: aspectRatio,
            negativePrompt: negative
        )
        
        print("Images saved:")
        for url in urls {
            print("- \(url.path)")
        }
    }
}