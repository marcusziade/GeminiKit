import Foundation

/// Available Gemini models with their capabilities and characteristics.
///
/// `GeminiModel` represents all available models in the Gemini family, including
/// text generation, image generation, video generation, text-to-speech, and embedding models.
/// Each model has different capabilities, performance characteristics, and use cases.
///
/// ## Topics
///
/// ### Text Generation Models
/// - ``gemini25Flash``
/// - ``gemini25Pro``
/// - ``gemini25FlashLite``
/// - ``gemini20Flash``
/// - ``gemini15Flash``
/// - ``gemini15Pro``
///
/// ### Image Generation Models
/// - ``gemini20FlashPreviewImageGeneration``
/// - ``imagen30Generate002``
/// - ``imagen40GeneratePreview``
///
/// ### Video Generation Models
/// - ``veo20Generate001``
///
/// ### Text-to-Speech Models
/// - ``gemini25FlashPreviewTTS``
/// - ``gemini25ProPreviewTTS``
///
/// ### Embedding Models
/// - ``textEmbedding004``
///
/// ### Model Properties
/// - ``modelId``
/// - ``supportsThinking``
/// - ``supportsImageGeneration``
/// - ``supportsVideoGeneration``
/// - ``supportsTTS``
/// - ``supportsEmbeddings``
/// - ``contextWindow``
/// - ``defaultThinkingBudget``
///
/// ## Choosing a Model
///
/// ### For General Use
/// - **Gemini 2.5 Flash**: Best balance of speed and capability
/// - **Gemini 2.5 Pro**: Highest quality for complex reasoning
/// - **Gemini 2.5 Flash Lite**: Fastest response times for simple tasks
///
/// ### For Specialized Tasks
/// - **Image Generation**: Use Imagen models for highest quality
/// - **Video Generation**: Use Veo 2.0 for video creation
/// - **Text-to-Speech**: Choose between Flash and Pro TTS variants
/// - **Embeddings**: Use text-embedding-004 for semantic search
///
/// ## Example
///
/// ```swift
/// // Text generation
/// let response = try await gemini.generateContent(
///     model: .gemini25Flash,
///     prompt: "Explain quantum computing"
/// )
///
/// // Check model capabilities
/// if model.supportsThinking {
///     // Enable thinking mode
/// }
///
/// // Get context window size
/// if let contextSize = model.contextWindow {
///     print("Model supports \(contextSize) tokens")
/// }
/// ```
public enum GeminiModel: String, CaseIterable, Sendable {
    // MARK: - Text Generation Models
    
    /// Gemini 2.5 Flash: Fast, versatile model with 1M token context window.
    /// Best for general-purpose tasks requiring speed and efficiency.
    case gemini25Flash = "gemini-2.5-flash"
    
    /// Gemini 2.5 Pro: Most capable model with 2M token context window.
    /// Ideal for complex reasoning, analysis, and creative tasks.
    case gemini25Pro = "gemini-2.5-pro"
    
    /// Gemini 2.5 Flash Lite: Lightweight variant optimized for minimal latency.
    /// Perfect for real-time applications and simple tasks.
    case gemini25FlashLite = "gemini-2.5-flash-lite"
    
    /// Gemini 2.0 Flash: Previous generation fast model with 1M token context.
    case gemini20Flash = "gemini-2.0-flash"
    
    /// Gemini 2.0 Flash with image generation capabilities.
    /// Combines text and image generation in a single model.
    case gemini20FlashPreviewImageGeneration = "gemini-2.0-flash-preview-image-generation"
    
    /// Gemini 1.5 Flash: Legacy fast model with 1M token context.
    case gemini15Flash = "gemini-1.5-flash"
    
    /// Gemini 1.5 Pro: Legacy pro model with 2M token context.
    case gemini15Pro = "gemini-1.5-pro"
    
    // MARK: - Text-to-Speech Models
    
    /// Gemini 2.5 Flash TTS: Fast text-to-speech synthesis.
    /// Supports multiple voices and languages with natural prosody.
    case gemini25FlashPreviewTTS = "gemini-2.5-flash-preview-tts"
    
    /// Gemini 2.5 Pro TTS: High-quality text-to-speech synthesis.
    /// Premium voices with enhanced emotional range and clarity.
    case gemini25ProPreviewTTS = "gemini-2.5-pro-preview-tts"
    
    // MARK: - Image Generation Models
    
    /// Imagen 3.0: High-quality image generation model.
    /// Creates photorealistic images from text descriptions.
    case imagen30Generate002 = "imagen-3.0-generate-002"
    
    /// Imagen 4.0 Preview: Next-generation image model.
    /// Enhanced creativity and adherence to prompts.
    case imagen40GeneratePreview = "imagen-4.0-generate-preview-06-06"
    
    // MARK: - Video Generation Models
    
    /// Veo 2.0: State-of-the-art video generation model.
    /// Creates short videos from text prompts or image references.
    case veo20Generate001 = "veo-2.0-generate-001"
    
    // MARK: - Embedding Models
    
    /// Text Embedding 004: Advanced semantic embedding model.
    /// Generates high-quality embeddings for search and similarity tasks.
    case textEmbedding004 = "text-embedding-004"
    
    // MARK: - Properties
    
    /// The model identifier string used in API requests.
    public var modelId: String {
        rawValue
    }
    
    /// Whether this model supports thinking mode for step-by-step reasoning.
    ///
    /// Thinking mode allows models to show their reasoning process before
    /// providing a final answer, useful for complex problem-solving.
    public var supportsThinking: Bool {
        switch self {
        case .gemini25Flash, .gemini25Pro, .gemini25FlashLite:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model can generate images from text prompts.
    public var supportsImageGeneration: Bool {
        switch self {
        case .gemini20FlashPreviewImageGeneration, .imagen30Generate002, .imagen40GeneratePreview:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model can generate videos from text or image inputs.
    public var supportsVideoGeneration: Bool {
        switch self {
        case .veo20Generate001:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model can convert text to natural-sounding speech.
    public var supportsTTS: Bool {
        switch self {
        case .gemini25FlashPreviewTTS, .gemini25ProPreviewTTS:
            return true
        default:
            return false
        }
    }
    
    /// Whether this model can generate embeddings for semantic tasks.
    public var supportsEmbeddings: Bool {
        switch self {
        case .textEmbedding004:
            return true
        default:
            return false
        }
    }
    
    /// The maximum context window size in tokens, if applicable.
    ///
    /// This represents the total number of tokens (input + output) the model
    /// can process in a single request. Larger windows allow for longer
    /// documents and conversations.
    ///
    /// - Returns: Token limit or nil for specialized models without text generation
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
    
    /// Default thinking budget for models that support thinking mode.
    ///
    /// The thinking budget controls how many tokens the model can use for
    /// internal reasoning before providing a response. A value of -1 indicates
    /// dynamic allocation based on task complexity.
    ///
    /// - Returns: Token budget or nil for models without thinking support
    public var defaultThinkingBudget: Int? {
        switch self {
        case .gemini25Flash, .gemini25Pro:
            return -1 // Dynamic allocation
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