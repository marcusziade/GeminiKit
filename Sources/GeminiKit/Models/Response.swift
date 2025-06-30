import Foundation

/// Response from content generation
public struct GenerateContentResponse: Codable, Equatable, Sendable {
    /// Generated candidates
    public let candidates: [Candidate]?
    
    /// Usage metadata
    public let usageMetadata: UsageMetadata?
    
    /// Model version used
    public let modelVersion: String?
}

/// A generated candidate response
public struct Candidate: Codable, Equatable, Sendable {
    /// The content of the candidate
    public let content: Content
    
    /// The reason generation stopped
    public let finishReason: FinishReason?
    
    /// Safety ratings
    public let safetyRatings: [SafetyRating]?
    
    /// Citation metadata
    public let citationMetadata: CitationMetadata?
    
    /// Token count for this candidate
    public let tokenCount: Int?
    
    /// Index of this candidate
    public let index: Int?
    
    /// Grounding metadata
    public let groundingMetadata: GroundingMetadata?
}

/// Reasons for generation completion
public enum FinishReason: String, Codable, Equatable, Sendable {
    case stop = "STOP"
    case maxTokens = "MAX_TOKENS"
    case safety = "SAFETY"
    case recitation = "RECITATION"
    case language = "LANGUAGE"
    case other = "OTHER"
    case blocklist = "BLOCKLIST"
    case prohibitedContent = "PROHIBITED_CONTENT"
    case spii = "SPII"
    case malformedFunctionCall = "MALFORMED_FUNCTION_CALL"
}

/// Safety rating for content
public struct SafetyRating: Codable, Equatable, Sendable {
    /// The category being rated
    public let category: HarmCategory
    
    /// The probability of harm
    public let probability: HarmProbability
    
    /// Whether content was blocked
    public let blocked: Bool?
}

/// Harm probability levels
public enum HarmProbability: String, Codable, Equatable, Sendable {
    case negligible = "NEGLIGIBLE"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

/// Citation metadata
public struct CitationMetadata: Codable, Equatable, Sendable {
    /// Citation sources
    public let citationSources: [CitationSource]
}

/// Citation source
public struct CitationSource: Codable, Equatable, Sendable {
    /// Start index of the citation
    public let startIndex: Int?
    
    /// End index of the citation
    public let endIndex: Int?
    
    /// URI of the source
    public let uri: String?
    
    /// License information
    public let license: String?
}

/// Usage metadata for the request
public struct UsageMetadata: Codable, Equatable, Sendable {
    /// Number of tokens in the prompt
    public let promptTokenCount: Int
    
    /// Number of tokens in the candidates
    public let candidatesTokenCount: Int?
    
    /// Total number of tokens
    public let totalTokenCount: Int
    
    /// Number of tokens in cached content
    public let cachedContentTokenCount: Int?
}

/// Response from token counting
public struct CountTokensResponse: Codable, Equatable, Sendable {
    /// Total number of tokens
    public let totalTokens: Int
    
    /// Number of tokens in cached content
    public let cachedContentTokenCount: Int?
}

/// Grounding metadata
public struct GroundingMetadata: Codable, Equatable, Sendable {
    /// Web search queries performed
    public let webSearchQueries: [String]?
    
    /// Search entry point
    public let searchEntryPoint: SearchEntryPoint?
    
    /// Grounding chunks
    public let groundingChunks: [GroundingChunk]?
    
    /// Grounding supports
    public let groundingSupports: [GroundingSupport]?
}

/// Search entry point
public struct SearchEntryPoint: Codable, Equatable, Sendable {
    /// The rendered content for search
    public let renderedContent: String?
}

/// Grounding chunk
public struct GroundingChunk: Codable, Equatable, Sendable {
    /// Web source
    public let web: WebSource?
}

/// Web source
public struct WebSource: Codable, Equatable, Sendable {
    /// URI of the web source
    public let uri: String?
    
    /// Title of the web source
    public let title: String?
}

/// Grounding support
public struct GroundingSupport: Codable, Equatable, Sendable {
    /// Segment of text
    public let segment: Segment?
    
    /// Indices of grounding chunks
    public let groundingChunkIndices: [Int]?
    
    /// Confidence scores
    public let confidenceScores: [Double]?
}

/// Text segment
public struct Segment: Codable, Equatable, Sendable {
    /// Part index
    public let partIndex: Int?
    
    /// Start index in the part
    public let startIndex: Int?
    
    /// End index in the part
    public let endIndex: Int?
    
    /// The text content
    public let text: String?
}

/// File information
public struct File: Codable, Equatable, Sendable {
    /// Resource name of the file
    public let name: String
    
    /// Display name of the file
    public let displayName: String?
    
    /// MIME type of the file
    public let mimeType: String
    
    /// Size of the file in bytes
    public let sizeBytes: String?
    
    /// Creation time
    public let createTime: String?
    
    /// Update time
    public let updateTime: String?
    
    /// Expiration time
    public let expirationTime: String?
    
    /// SHA256 hash of the file
    public let sha256Hash: String?
    
    /// URI of the file
    public let uri: String?
    
    /// State of the file
    public let state: FileState?
    
    /// Error information
    public let error: Status?
    
    /// Video metadata
    public let videoMetadata: VideoMetadata?
}

/// File state
public enum FileState: String, Codable, Equatable, Sendable {
    case processing = "PROCESSING"
    case active = "ACTIVE"
    case failed = "FAILED"
}

/// Status information for errors
public struct Status: Codable, Equatable, Sendable {
    /// Error code
    public let code: Int?
    
    /// Error message
    public let message: String?
    
    /// Additional details
    public let details: [AnyCodable]?
}

/// List files response
public struct ListFilesResponse: Codable, Equatable, Sendable {
    /// List of files
    public let files: [File]?
    
    /// Token for next page
    public let nextPageToken: String?
}