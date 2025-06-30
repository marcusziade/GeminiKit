import Foundation

// MARK: - Image Generation Models

/// Request for Imagen image generation
public struct ImagenPredictRequest: Codable, Equatable, Sendable {
    public let instances: [ImagenInstance]
    public let parameters: ImagenParameters
    
    public init(prompt: String, parameters: ImagenParameters) {
        self.instances = [ImagenInstance(prompt: prompt)]
        self.parameters = parameters
    }
}

/// Imagen instance
public struct ImagenInstance: Codable, Equatable, Sendable {
    public let prompt: String
    
    public init(prompt: String) {
        self.prompt = prompt
    }
}

/// Imagen parameters
public struct ImagenParameters: Codable, Equatable, Sendable {
    public let sampleCount: Int?
    public let aspectRatio: String?
    public let personGeneration: String?
    public let negativePrompt: String?
    
    public init(
        sampleCount: Int? = 1,
        aspectRatio: String? = "1:1",
        personGeneration: String? = nil,
        negativePrompt: String? = nil
    ) {
        self.sampleCount = sampleCount
        self.aspectRatio = aspectRatio
        self.personGeneration = personGeneration
        self.negativePrompt = negativePrompt
    }
}

/// Response from Imagen prediction
public struct ImagenPredictResponse: Codable, Equatable, Sendable {
    public let predictions: [ImagenPrediction]
}

/// Imagen prediction
public struct ImagenPrediction: Codable, Equatable, Sendable {
    public let bytesBase64Encoded: String
    public let mimeType: String
}

// MARK: - Video Generation Models

/// Request for Veo video generation
public struct VeoPredictRequest: Codable, Equatable, Sendable {
    public let instances: [VeoInstance]
    public let parameters: VeoParameters
    
    public init(
        prompt: String,
        image: String? = nil,
        parameters: VeoParameters
    ) {
        self.instances = [VeoInstance(prompt: prompt, image: image)]
        self.parameters = parameters
    }
}

/// Veo instance
public struct VeoInstance: Codable, Equatable, Sendable {
    public let prompt: String
    public let image: String?
    
    public init(prompt: String, image: String? = nil) {
        self.prompt = prompt
        self.image = image
    }
}

/// Veo parameters
public struct VeoParameters: Codable, Equatable, Sendable {
    public let aspectRatio: String?
    public let personGeneration: String?
    public let numberOfVideos: Int?
    public let durationSeconds: Int?
    public let enhancePrompt: Bool?
    
    public init(
        aspectRatio: String? = "16:9",
        personGeneration: String? = nil,
        numberOfVideos: Int? = 1,
        durationSeconds: Int? = 5,
        enhancePrompt: Bool? = true
    ) {
        self.aspectRatio = aspectRatio
        self.personGeneration = personGeneration
        self.numberOfVideos = numberOfVideos
        self.durationSeconds = durationSeconds
        self.enhancePrompt = enhancePrompt
    }
}

/// Response from Veo prediction (initial)
public struct VeoPredictResponse: Codable, Equatable, Sendable {
    public let name: String
    public let metadata: OperationMetadata?
}

/// Operation metadata
public struct OperationMetadata: Codable, Equatable, Sendable {
    public let createTime: String?
    public let updateTime: String?
}

/// Long-running operation response
public struct Operation: Codable, Equatable, Sendable {
    public let name: String
    public let done: Bool?
    public let error: Status?
    public let response: OperationResponse?
    public let metadata: OperationMetadata?
}

/// Operation response
public struct OperationResponse: Codable, Equatable, Sendable {
    public let predictions: [VeoPrediction]?
}

/// Veo prediction
public struct VeoPrediction: Codable, Equatable, Sendable {
    public let video: VideoData?
}

/// Video data
public struct VideoData: Codable, Equatable, Sendable {
    public let uri: String?
    public let bytesBase64Encoded: String?
}

// MARK: - TTS Models

/// Speech generation request
public struct SpeechGenerationRequest: Codable, Equatable, Sendable {
    public let contents: [Content]
    public let generationConfig: SpeechGenerationConfig
    
    public init(text: String, voice: String, language: String? = nil) {
        self.contents = [Content.user(text)]
        self.generationConfig = SpeechGenerationConfig(
            speechConfig: SpeechConfig(
                voiceConfig: VoiceConfig(voiceName: voice)
            )
        )
    }
    
    public init(speakers: [(speaker: String, text: String, voice: String)]) {
        var parts: [Part] = []
        let voiceConfigs = speakers.map { speaker in
            parts.append(.text("<speaker id=\"\(speaker.speaker)\">\(speaker.text)</speaker>"))
            return SpeakerVoiceConfig(speaker: speaker.speaker, voiceName: speaker.voice)
        }
        
        self.contents = [Content(role: .user, parts: parts)]
        self.generationConfig = SpeechGenerationConfig(
            speechConfig: SpeechConfig(
                multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig(
                    speakerVoiceConfigs: voiceConfigs
                )
            )
        )
    }
}

/// Speech generation config
public struct SpeechGenerationConfig: Codable, Equatable, Sendable {
    public let speechConfig: SpeechConfig
    public var responseModalities: [ResponseModality] = [.audio]
    
    public init(speechConfig: SpeechConfig) {
        self.speechConfig = speechConfig
    }
}

/// Speech response
public struct SpeechGenerationResponse: Codable, Equatable, Sendable {
    public let candidates: [SpeechCandidate]?
    public let usageMetadata: UsageMetadata?
}

/// Speech candidate
public struct SpeechCandidate: Codable, Equatable, Sendable {
    public let content: Content
    public let finishReason: FinishReason?
}

// MARK: - Aspect Ratios

/// Supported aspect ratios for image generation
public enum ImageAspectRatio: String, CaseIterable, Sendable {
    case square = "1:1"
    case portrait = "3:4"
    case landscape = "4:3"
    case widePortrait = "9:16"
    case wideLandscape = "16:9"
}

/// Supported aspect ratios for video generation
public enum VideoAspectRatio: String, CaseIterable, Sendable {
    case landscape = "16:9"
    case portrait = "9:16"
}

/// Person generation options
public enum PersonGeneration: String, CaseIterable, Sendable {
    case dontAllow = "dont_allow"
    case allowAdult = "allow_adult"
    case allowAll = "allow_all"
}