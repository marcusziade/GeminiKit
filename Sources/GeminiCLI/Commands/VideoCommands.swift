import ArgumentParser
import Foundation
import GeminiKit

/// Command for generating videos from text
struct GenerateVideoCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-video",
        abstract: "Generate videos from text"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt for video generation")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "Duration in seconds (5 or 8)")
    var duration: Int = 5
    
    @Option(name: .shortAndLong, help: "Aspect ratio (16:9 or 9:16)")
    var ratio: String = "16:9"
    
    @Option(help: "Image file for image-to-video")
    var image: String?
    
    @Flag(help: "Wait for completion")
    var wait = false
    
    func execute(with gemini: GeminiKit) async throws {
        guard duration == 5 || duration == 8 else {
            throw GeminiError.invalidRequest("Duration must be 5 or 8 seconds")
        }
        
        var imageData: String?
        if let imagePath = image {
            let imageURL = try FileHelper.validateFile(at: imagePath)
            let data = try FileHelper.loadFileData(from: imageURL)
            imageData = data.base64EncodedString()
        }
        
        let aspectRatio = VideoAspectRatio(rawValue: ratio) ?? .landscape
        
        let operation = try await gemini.generateVideos(
            prompt: prompt,
            imageData: imageData,
            aspectRatio: aspectRatio,
            duration: duration
        )
        
        print("Starting video generation...")
        
        print("Operation started: \(operation)")
        
        if wait {
            print("Waiting for completion...")
            let videos = try await gemini.waitForVideos(operation)
            
            print("Videos generated:")
            for (index, video) in videos.enumerated() {
                if let uri = video.video?.uri {
                    print("- Video \(index + 1): \(uri)")
                }
            }
        }
    }
}

/// Command for analyzing video content
struct AnalyzeVideoCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze-video",
        abstract: "Analyze video content"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "Path to video file or YouTube URL")
    var video: String
    
    @Option(name: .shortAndLong, help: "Analysis prompt")
    var prompt: String = "Please describe this video in detail."
    
    @Option(help: "System instruction")
    var system: String?
    
    @Option(help: "Start time (MM:SS format)")
    var start: String?
    
    @Option(help: "End time (MM:SS format)")
    var end: String?
    
    @Option(help: "Frames per second (default: 1)")
    var fps: Double?
    
    @Flag(help: "Transcribe audio and provide visual descriptions")
    var transcribe = false
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
        var parts: [Part] = []
        
        // Check if it's a YouTube URL
        if video.starts(with: "https://www.youtube.com/") || video.starts(with: "https://youtu.be/") {
            // Use YouTube URL directly
            parts.append(.fileData(FileData(
                mimeType: "video/*",
                fileUri: video
            )))
        } else {
            // Upload local video file
            let videoURL = try FileHelper.validateFile(at: video)
            print("Uploading video file...")
            
            let file = try await gemini.uploadFile(from: videoURL)
            print("Video uploaded: \(file.name)")
            
            // Wait a moment for processing
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            parts.append(.fileData(FileData(
                mimeType: file.mimeType,
                fileUri: file.uri ?? ""
            )))
        }
        
        // Add video metadata if specified
        if start != nil || end != nil || fps != nil {
            parts.append(.videoMetadata(VideoMetadata(
                startOffset: start,
                endOffset: end,
                fps: fps
            )))
        }
        
        // Add the analysis prompt
        let analysisPrompt = transcribe ?
            "\(prompt)\n\nPlease also transcribe the audio from this video, giving timestamps for salient events. Also provide visual descriptions." :
            prompt
        parts.append(.text(analysisPrompt))
        
        let content = Content(role: .user, parts: parts)
        
        print("Analyzing video...")
        
        let response = try await gemini.generateContent(
            model: model,
            messages: [content],
            systemInstruction: system
        )
        
        OutputFormatter.printContent(response)
    }
}