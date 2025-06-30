import Foundation

/// Specialized endpoints extension for GeminiKit
extension GeminiKit {
    
    // MARK: - Image Generation
    
    /// Generates images using Imagen models
    /// - Parameters:
    ///   - model: The Imagen model to use
    ///   - prompt: The text prompt for image generation
    ///   - count: Number of images to generate (1-4)
    ///   - aspectRatio: The aspect ratio for generated images
    ///   - personGeneration: Person generation policy
    ///   - negativePrompt: Things to avoid in the generated image
    /// - Returns: Generated images as base64-encoded data
    public func generateImages(
        model: GeminiModel = .imagen30Generate002,
        prompt: String,
        count: Int = 1,
        aspectRatio: ImageAspectRatio = .square,
        personGeneration: PersonGeneration? = nil,
        negativePrompt: String? = nil
    ) async throws -> [ImagenPrediction] {
        guard model.supportsImageGeneration else {
            throw GeminiError.invalidRequest("Model \(model.rawValue) does not support image generation")
        }
        
        guard count >= 1 && count <= 4 else {
            throw GeminiError.invalidRequest("Image count must be between 1 and 4")
        }
        
        let parameters = ImagenParameters(
            sampleCount: count,
            aspectRatio: aspectRatio.rawValue,
            personGeneration: personGeneration?.rawValue,
            negativePrompt: negativePrompt
        )
        
        let request = ImagenPredictRequest(prompt: prompt, parameters: parameters)
        
        let endpoint = "/models/\(model.rawValue):predict"
        let response: ImagenPredictResponse = try await apiClient.request(
            endpoint: endpoint,
            body: request
        )
        
        return response.predictions
    }
    
    /// Generates images and saves them to files
    /// - Parameters:
    ///   - model: The Imagen model to use
    ///   - prompt: The text prompt for image generation
    ///   - outputDirectory: Directory to save images
    ///   - count: Number of images to generate
    ///   - aspectRatio: The aspect ratio for generated images
    ///   - personGeneration: Person generation policy
    ///   - negativePrompt: Things to avoid in the generated image
    /// - Returns: URLs of saved image files
    public func generateImageFiles(
        model: GeminiModel = .imagen30Generate002,
        prompt: String,
        outputDirectory: URL,
        count: Int = 1,
        aspectRatio: ImageAspectRatio = .square,
        personGeneration: PersonGeneration? = nil,
        negativePrompt: String? = nil
    ) async throws -> [URL] {
        let predictions = try await generateImages(
            model: model,
            prompt: prompt,
            count: count,
            aspectRatio: aspectRatio,
            personGeneration: personGeneration,
            negativePrompt: negativePrompt
        )
        
        var savedURLs: [URL] = []
        
        for (index, prediction) in predictions.enumerated() {
            guard let imageData = Data(base64Encoded: prediction.bytesBase64Encoded) else {
                throw GeminiError.invalidResponse("Failed to decode image data")
            }
            
            let filename = "image_\(index + 1).\(fileExtension(for: prediction.mimeType))"
            let fileURL = outputDirectory.appendingPathComponent(filename)
            
            try imageData.write(to: fileURL)
            savedURLs.append(fileURL)
        }
        
        return savedURLs
    }
    
    // MARK: - Video Generation
    
    /// Generates videos using Veo models
    /// - Parameters:
    ///   - model: The Veo model to use
    ///   - prompt: The text prompt for video generation
    ///   - imageData: Optional base64-encoded image for image-to-video
    ///   - aspectRatio: The aspect ratio for generated videos
    ///   - duration: Duration in seconds (5 or 8)
    ///   - count: Number of videos to generate (1-2)
    ///   - personGeneration: Person generation policy
    /// - Returns: Operation name for tracking the generation progress
    public func generateVideos(
        model: GeminiModel = .veo20Generate001,
        prompt: String,
        imageData: String? = nil,
        aspectRatio: VideoAspectRatio = .landscape,
        duration: Int = 5,
        count: Int = 1,
        personGeneration: PersonGeneration? = nil
    ) async throws -> String {
        guard model.supportsVideoGeneration else {
            throw GeminiError.invalidRequest("Model \(model.rawValue) does not support video generation")
        }
        
        guard duration == 5 || duration == 8 else {
            throw GeminiError.invalidRequest("Video duration must be 5 or 8 seconds")
        }
        
        guard count >= 1 && count <= 2 else {
            throw GeminiError.invalidRequest("Video count must be 1 or 2")
        }
        
        let parameters = VeoParameters(
            aspectRatio: aspectRatio.rawValue,
            personGeneration: personGeneration?.rawValue,
            numberOfVideos: count,
            durationSeconds: duration
        )
        
        let request = VeoPredictRequest(
            prompt: prompt,
            image: imageData,
            parameters: parameters
        )
        
        let endpoint = "/models/\(model.rawValue):predictLongRunning"
        
        do {
            let response: VeoPredictResponse = try await apiClient.request(
                endpoint: endpoint,
                body: request
            )
            return response.name
        } catch {
            // Try alternative response format
            if let operation: Operation = try? await apiClient.request(
                endpoint: endpoint,
                body: request
            ) {
                return operation.name
            }
            throw error
        }
    }
    
    /// Checks the status of a video generation operation
    /// - Parameter operationName: The operation name returned from generateVideos
    /// - Returns: The operation status and results if complete
    public func getVideoOperation(_ operationName: String) async throws -> Operation {
        let endpoint = "/\(operationName)"
        return try await apiClient.request(
            endpoint: endpoint,
            method: "GET",
            body: nil as String?
        )
    }
    
    /// Waits for video generation to complete and returns the results
    /// - Parameters:
    ///   - operationName: The operation name returned from generateVideos
    ///   - pollingInterval: Time between status checks in seconds
    ///   - timeout: Maximum time to wait in seconds
    /// - Returns: The completed video predictions
    public func waitForVideos(
        _ operationName: String,
        pollingInterval: TimeInterval = 5,
        timeout: TimeInterval = 300
    ) async throws -> [VeoPrediction] {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            let operation = try await getVideoOperation(operationName)
            
            if operation.done == true {
                if let error = operation.error {
                    throw GeminiError.apiError(
                        code: error.code ?? 0,
                        message: error.message ?? "Video generation failed",
                        details: nil
                    )
                }
                
                guard let predictions = operation.response?.predictions else {
                    throw GeminiError.invalidResponse("No video predictions in response")
                }
                
                return predictions
            }
            
            try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
        }
        
        throw GeminiError.timeout
    }
    
    // MARK: - Text-to-Speech
    
    /// Generates speech from text
    /// - Parameters:
    ///   - model: The TTS model to use
    ///   - text: The text to convert to speech
    ///   - voice: The voice to use
    ///   - language: Optional language code
    /// - Returns: Audio data as base64-encoded string
    public func generateSpeech(
        model: GeminiModel = .gemini25FlashPreviewTTS,
        text: String,
        voice: TTSVoice
    ) async throws -> Data {
        guard model.supportsTTS else {
            throw GeminiError.invalidRequest("Model \(model.rawValue) does not support TTS")
        }
        
        let request = SpeechGenerationRequest(text: text, voice: voice.rawValue)
        
        let response = try await generateContent(
            model: model,
            request: GenerateContentRequest(
                contents: request.contents,
                generationConfig: GenerationConfig(
                    responseModalities: [.audio],
                    speechConfig: request.generationConfig.speechConfig
                )
            )
        )
        
        guard let candidate = response.candidates?.first else {
            throw GeminiError.invalidResponse("No audio generated")
        }
        
        for part in candidate.content.parts {
            if case .inlineData(let data) = part,
               data.mimeType.starts(with: "audio/") {
                guard let audioData = Data(base64Encoded: data.data) else {
                    throw GeminiError.invalidResponse("Failed to decode audio data")
                }
                return audioData
            }
        }
        
        throw GeminiError.invalidResponse("No audio data in response")
    }
    
    /// Generates multi-speaker speech
    /// - Parameters:
    ///   - model: The TTS model to use
    ///   - speakers: Array of speaker configurations
    /// - Returns: Audio data as base64-encoded string
    public func generateMultiSpeakerSpeech(
        model: GeminiModel = .gemini25FlashPreviewTTS,
        speakers: [(speaker: String, text: String, voice: TTSVoice)]
    ) async throws -> Data {
        guard model.supportsTTS else {
            throw GeminiError.invalidRequest("Model \(model.rawValue) does not support TTS")
        }
        
        guard speakers.count <= 2 else {
            throw GeminiError.invalidRequest("Maximum 2 speakers allowed")
        }
        
        let speakerData = speakers.map { ($0.speaker, $0.text, $0.voice.rawValue) }
        let request = SpeechGenerationRequest(speakers: speakerData)
        
        let response = try await generateContent(
            model: model,
            request: GenerateContentRequest(
                contents: request.contents,
                generationConfig: GenerationConfig(
                    responseModalities: [.audio],
                    speechConfig: request.generationConfig.speechConfig
                )
            )
        )
        
        guard let candidate = response.candidates?.first else {
            throw GeminiError.invalidResponse("No audio generated")
        }
        
        for part in candidate.content.parts {
            if case .inlineData(let data) = part,
               data.mimeType.starts(with: "audio/") {
                guard let audioData = Data(base64Encoded: data.data) else {
                    throw GeminiError.invalidResponse("Failed to decode audio data")
                }
                return audioData
            }
        }
        
        throw GeminiError.invalidResponse("No audio data in response")
    }
    
    /// Saves audio data to a file
    /// - Parameters:
    ///   - audioData: The audio data to save
    ///   - outputURL: The URL to save the audio file
    public func saveAudioToFile(_ audioData: Data, outputURL: URL) throws {
        try audioData.write(to: outputURL)
    }
    
    // MARK: - Helper Methods
    
    private func fileExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/png": return "png"
        case "image/jpeg": return "jpg"
        case "image/gif": return "gif"
        case "image/webp": return "webp"
        case "video/mp4": return "mp4"
        case "video/mpeg": return "mpeg"
        case "video/webm": return "webm"
        case "audio/wav": return "wav"
        case "audio/mp3", "audio/mpeg": return "mp3"
        case "audio/aac": return "aac"
        default: return "bin"
        }
    }
}