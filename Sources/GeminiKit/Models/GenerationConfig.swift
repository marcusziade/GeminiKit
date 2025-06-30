import Foundation

/// Configuration parameters for content generation
public struct GenerationConfig: Codable, Equatable, Sendable {
    /// Controls randomness in generation (0.0 to 2.0)
    public let temperature: Double?
    
    /// Nucleus sampling parameter (0.0 to 1.0)
    public let topP: Double?
    
    /// Top-k sampling parameter
    public let topK: Int?
    
    /// Number of response candidates to generate
    public let candidateCount: Int?
    
    /// Maximum number of tokens to generate
    public let maxOutputTokens: Int?
    
    /// Sequences that will stop generation
    public let stopSequences: [String]?
    
    /// Output modalities for the response
    public let responseModalities: [ResponseModality]?
    
    /// MIME type for the response
    public let responseMimeType: String?
    
    /// JSON schema for structured output
    public let responseSchema: ResponseSchema?
    
    /// Configuration for thinking mode
    public let thinkingConfig: ThinkingConfig?
    
    /// Configuration for speech generation
    public let speechConfig: SpeechConfig?
    
    /// Creates a new generation configuration
    public init(
        temperature: Double? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        candidateCount: Int? = nil,
        maxOutputTokens: Int? = nil,
        stopSequences: [String]? = nil,
        responseModalities: [ResponseModality]? = nil,
        responseMimeType: String? = nil,
        responseSchema: ResponseSchema? = nil,
        thinkingConfig: ThinkingConfig? = nil,
        speechConfig: SpeechConfig? = nil
    ) {
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.candidateCount = candidateCount
        self.maxOutputTokens = maxOutputTokens
        self.stopSequences = stopSequences
        self.responseModalities = responseModalities
        self.responseMimeType = responseMimeType
        self.responseSchema = responseSchema
        self.thinkingConfig = thinkingConfig
        self.speechConfig = speechConfig
    }
}

/// Output modalities for the response
public enum ResponseModality: String, Codable, Equatable, Sendable {
    case text = "TEXT"
    case audio = "AUDIO"
    case image = "IMAGE"
}

/// Response MIME types
public enum ResponseMimeType: String, Codable, Equatable, Sendable {
    case plainText = "text/plain"
    case json = "application/json"
    case enumeration = "text/x.enum"
}

/// Schema for structured output
public indirect enum ResponseSchema: Codable, Equatable, Sendable {
    case string(enum: [String]?)
    case number
    case integer
    case boolean
    case array(items: ResponseSchema)
    case object(properties: [String: ResponseSchema], required: [String]?, propertyOrdering: [String]?)
    
    private enum CodingKeys: String, CodingKey {
        case type, properties, required, items, `enum`, propertyOrdering
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "STRING":
            let enumValues = try container.decodeIfPresent([String].self, forKey: .enum)
            self = .string(enum: enumValues)
        case "NUMBER":
            self = .number
        case "INTEGER":
            self = .integer
        case "BOOLEAN":
            self = .boolean
        case "ARRAY":
            let items = try container.decode(ResponseSchema.self, forKey: .items)
            self = .array(items: items)
        case "OBJECT":
            let properties = try container.decode([String: ResponseSchema].self, forKey: .properties)
            let required = try container.decodeIfPresent([String].self, forKey: .required)
            let propertyOrdering = try container.decodeIfPresent([String].self, forKey: .propertyOrdering)
            self = .object(properties: properties, required: required, propertyOrdering: propertyOrdering)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .string(let enumValues):
            try container.encode("STRING", forKey: .type)
            try container.encodeIfPresent(enumValues, forKey: .enum)
        case .number:
            try container.encode("NUMBER", forKey: .type)
        case .integer:
            try container.encode("INTEGER", forKey: .type)
        case .boolean:
            try container.encode("BOOLEAN", forKey: .type)
        case .array(let items):
            try container.encode("ARRAY", forKey: .type)
            try container.encode(items, forKey: .items)
        case .object(let properties, let required, let propertyOrdering):
            try container.encode("OBJECT", forKey: .type)
            try container.encode(properties, forKey: .properties)
            try container.encodeIfPresent(required, forKey: .required)
            try container.encodeIfPresent(propertyOrdering, forKey: .propertyOrdering)
        }
    }
}

/// Schema types
public enum SchemaType: String, Codable, Equatable, Sendable {
    case string = "STRING"
    case number = "NUMBER"
    case integer = "INTEGER"
    case boolean = "BOOLEAN"
    case array = "ARRAY"
    case object = "OBJECT"
}

/// Configuration for thinking mode
public struct ThinkingConfig: Codable, Equatable, Sendable {
    /// Number of thinking tokens (-1 for dynamic)
    public let thinkingBudget: Int
    
    /// Whether to include thought summaries in the response
    public let includeThoughts: Bool?
    
    /// Creates a new thinking configuration
    /// - Parameters:
    ///   - thinkingBudget: Number of thinking tokens (-1 for dynamic)
    ///   - includeThoughts: Whether to include thought summaries
    public init(thinkingBudget: Int = -1, includeThoughts: Bool? = nil) {
        self.thinkingBudget = thinkingBudget
        self.includeThoughts = includeThoughts
    }
}

/// Configuration for speech generation
public struct SpeechConfig: Codable, Equatable, Sendable {
    /// Voice configuration for single speaker
    public let voiceConfig: VoiceConfig?
    
    /// Voice configuration for multiple speakers
    public let multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig?
    
    /// Creates a new speech configuration
    public init(
        voiceConfig: VoiceConfig? = nil,
        multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig? = nil
    ) {
        self.voiceConfig = voiceConfig
        self.multiSpeakerVoiceConfig = multiSpeakerVoiceConfig
    }
}

/// Voice configuration
public struct VoiceConfig: Codable, Equatable, Sendable {
    /// Prebuilt voice configuration
    public let prebuiltVoiceConfig: PrebuiltVoiceConfig
    
    /// Creates a new voice configuration
    /// - Parameter voiceName: The name of the voice to use
    public init(voiceName: String) {
        self.prebuiltVoiceConfig = PrebuiltVoiceConfig(voiceName: voiceName)
    }
}

/// Prebuilt voice configuration
public struct PrebuiltVoiceConfig: Codable, Equatable, Sendable {
    /// The name of the voice to use
    public let voiceName: String
    
    /// Creates a new prebuilt voice configuration
    /// - Parameter voiceName: The name of the voice to use
    public init(voiceName: String) {
        self.voiceName = voiceName
    }
}

/// Multi-speaker voice configuration
public struct MultiSpeakerVoiceConfig: Codable, Equatable, Sendable {
    /// Speaker voice configurations
    public let speakerVoiceConfigs: [SpeakerVoiceConfig]
    
    /// Creates a new multi-speaker voice configuration
    /// - Parameter speakerVoiceConfigs: Speaker voice configurations
    public init(speakerVoiceConfigs: [SpeakerVoiceConfig]) {
        self.speakerVoiceConfigs = speakerVoiceConfigs
    }
}

/// Speaker voice configuration
public struct SpeakerVoiceConfig: Codable, Equatable, Sendable {
    /// The speaker ID
    public let speaker: String
    
    /// The voice name for this speaker
    public let voiceName: String
    
    /// Creates a new speaker voice configuration
    /// - Parameters:
    ///   - speaker: The speaker ID
    ///   - voiceName: The voice name for this speaker
    public init(speaker: String, voiceName: String) {
        self.speaker = speaker
        self.voiceName = voiceName
    }
}

/// Box type to work around Swift's recursive type limitations
public struct Box<T: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(T.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        lhs.value == rhs.value
    }
}