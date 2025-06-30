import Foundation

/// Available Gemini models
public enum GeminiModel: String, CaseIterable, Sendable {
    // Text generation models
    case gemini25Flash = "gemini-2.5-flash"
    case gemini25Pro = "gemini-2.5-pro"
    case gemini25FlashLite = "gemini-2.5-flash-lite"
    case gemini20Flash = "gemini-2.0-flash"
    case gemini20FlashPreviewImageGeneration = "gemini-2.0-flash-preview-image-generation"
    case gemini15Flash = "gemini-1.5-flash"
    case gemini15Pro = "gemini-1.5-pro"
    
    // TTS models
    case gemini25FlashPreviewTTS = "gemini-2.5-flash-preview-tts"
    case gemini25ProPreviewTTS = "gemini-2.5-pro-preview-tts"
    
    // Image generation models
    case imagen30Generate002 = "imagen-3.0-generate-002"
    case imagen40GeneratePreview = "imagen-4.0-generate-preview-06-06"
    
    // Video generation models
    case veo20Generate001 = "veo-2.0-generate-001"
    
    // Embedding model
    case textEmbedding004 = "text-embedding-004"
    
    /// The model identifier
    public var modelId: String {
        rawValue
    }
    
    /// Whether this model supports thinking mode
    public var supportsThinking: Bool {
        switch self {
        case .gemini25Flash, .gemini25Pro, .gemini25FlashLite:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model supports image generation
    public var supportsImageGeneration: Bool {
        switch self {
        case .gemini20FlashPreviewImageGeneration, .imagen30Generate002, .imagen40GeneratePreview:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model supports video generation
    public var supportsVideoGeneration: Bool {
        switch self {
        case .veo20Generate001:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model supports text-to-speech
    public var supportsTTS: Bool {
        switch self {
        case .gemini25FlashPreviewTTS, .gemini25ProPreviewTTS:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model supports embeddings
    public var supportsEmbeddings: Bool {
        switch self {
        case .textEmbedding004:
            return true
        default:
            return false
        }
    }
    
    /// The context window size in tokens
    public var contextWindow: Int? {
        switch self {
        case .gemini25Flash, .gemini25FlashLite, .gemini20Flash, .gemini15Flash:
            return 1_000_000
        case .gemini25Pro, .gemini15Pro:
            return 2_000_000
        default:
            return nil
        }
    }
    
    /// Default thinking budget for models that support thinking
    public var defaultThinkingBudget: Int? {
        switch self {
        case .gemini25Flash, .gemini25Pro:
            return -1 // Dynamic
        case .gemini25FlashLite:
            return 0 // Off by default
        default:
            return nil
        }
    }
    
    /// Thinking budget range for models that support thinking
    public var thinkingBudgetRange: ClosedRange<Int>? {
        switch self {
        case .gemini25Flash:
            return 0...24576
        case .gemini25Pro:
            return 128...32768
        case .gemini25FlashLite:
            return 512...24576
        default:
            return nil
        }
    }
}

/// Available TTS voices
public enum TTSVoice: String, CaseIterable, Sendable {
    case zephyr = "Zephyr"
    case puck = "Puck"
    case charon = "Charon"
    case kore = "Kore"
    case fenrir = "Fenrir"
    case leda = "Leda"
    case orus = "Orus"
    case aoede = "Aoede"
    case callirrhoe = "Callirrhoe"
    case autonoe = "Autonoe"
    case enceladus = "Enceladus"
    case iapetus = "Iapetus"
    case umbriel = "Umbriel"
    case algieba = "Algieba"
    case despina = "Despina"
    case erinome = "Erinome"
    case algenib = "Algenib"
    case rasalgethi = "Rasalgethi"
    case laomedeia = "Laomedeia"
    case achernar = "Achernar"
    case alnilam = "Alnilam"
    case schedar = "Schedar"
    case gacrux = "Gacrux"
    case pulcherrima = "Pulcherrima"
    case achird = "Achird"
    case zubenelgenubi = "Zubenelgenubi"
    case vindemiatrix = "Vindemiatrix"
    case sadachbia = "Sadachbia"
    case sadaltager = "Sadaltager"
    case sulafat = "Sulafat"
}

/// Supported languages for TTS
public enum TTSLanguage: String, CaseIterable, Sendable {
    case arabicEgypt = "ar-EG"
    case englishUS = "en-US"
    case german = "de-DE"
    case spanishUS = "es-US"
    case french = "fr-FR"
    case hindi = "hi-IN"
    case indonesian = "id-ID"
    case italian = "it-IT"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case portugueseBrazil = "pt-BR"
    case russian = "ru-RU"
    case dutch = "nl-NL"
    case polish = "pl-PL"
    case thai = "th-TH"
    case turkish = "tr-TR"
    case vietnamese = "vi-VN"
    case romanian = "ro-RO"
    case ukrainian = "uk-UA"
    case bengali = "bn-BD"
    case englishIndia = "en-IN"
    case marathi = "mr-IN"
    case tamil = "ta-IN"
    case telugu = "te-IN"
}