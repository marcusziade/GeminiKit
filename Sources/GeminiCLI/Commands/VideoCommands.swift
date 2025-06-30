import ArgumentParser
import Foundation
import GeminiKit

/// Command for generating videos from text
struct GenerateVideoCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-video",
        abstract: "Generate videos from text",
        discussion: """
        Generate videos using AI from text prompts or existing images.
        Note: Video generation requires a paid API tier.
        
        Examples:
          # Text-to-video generation
          gemini-cli generate-video "Ocean waves at sunset" --wait
          
          # Vertical video for social media
          gemini-cli generate-video "Neon city lights" \\
            --ratio 9:16 \\
            --duration 8 \\
            --wait
          
          # Image-to-video animation
          gemini-cli generate-video "Animate this scene with gentle movement" \\
            --image landscape.jpg \\
            --wait
        """
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt describing the video to generate")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "Video duration in seconds (5 or 8, default: 5)")
    var duration: Int = 5
    
    @Option(name: .shortAndLong, help: "Aspect ratio (16:9 for landscape, 9:16 for portrait, default: 16:9)")
    var ratio: String = "16:9"
    
    @Option(help: "Path to source image for image-to-video generation")
    var image: String?
    
    @Flag(help: "Wait for video generation to complete (recommended)")
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
        abstract: "Analyze video content",
        discussion: """
        Analyze video files or YouTube videos using AI to extract insights, summaries, and descriptions.
        
        Examples:
          # Analyze local video file
          gemini-cli analyze-video presentation.mp4 \\
            --prompt "Summarize the key points"
          
          # Analyze YouTube video
          gemini-cli analyze-video "https://youtu.be/VIDEO_ID" \\
            --prompt "What are the main topics discussed?"
          
          # Analyze specific segment with transcription
          gemini-cli analyze-video lecture.mp4 \\
            --start 05:30 \\
            --end 10:45 \\
            --transcribe \\
            --prompt "Extract the key concepts"
          
          # Frame-by-frame analysis
          gemini-cli analyze-video action_scene.mp4 \\
            --fps 5 \\
            --prompt "Describe the action sequence in detail"
        """
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "Path to local video file or YouTube URL (e.g., https://youtu.be/VIDEO_ID)")
    var video: String
    
    @Option(name: .shortAndLong, help: "Custom analysis prompt (default: 'Please describe this video in detail.')")
    var prompt: String = "Please describe this video in detail."
    
    @Option(help: "System instruction to guide the analysis")
    var system: String?
    
    @Option(help: "Start time for analysis in MM:SS format (e.g., 01:30)")
    var start: String?
    
    @Option(help: "End time for analysis in MM:SS format (e.g., 05:45)")
    var end: String?
    
    @Option(help: "Frames per second to analyze (default: 1, higher values for detailed frame analysis)")
    var fps: Double?
    
    @Flag(help: "Include audio transcription with timestamps and visual descriptions")
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