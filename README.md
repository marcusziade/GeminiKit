# GeminiKit

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgray.svg)](https://github.com/marcusziade/GeminiKit)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A comprehensive Swift SDK for the Google Gemini API with full feature coverage and a powerful CLI.

## Features

- 🚀 **Complete API Coverage**: Text/image/video generation, analysis, TTS, embeddings
- 🌐 **Cross-Platform**: macOS, iOS, tvOS, watchOS, and Linux
- 🔄 **Streaming Support**: Real-time response streaming with SSE
- 🛠 **CLI Tool**: Full-featured command-line interface
- 🔌 **OpenAI Compatible**: Drop-in replacement for OpenAI clients
- ⚡ **Type-Safe**: Strongly typed with comprehensive error handling

## Installation

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/marcusziade/GeminiKit", from: "1.0.0")
]
```

### CLI
```bash
# Build from source
swift build -c release --product gemini-cli
cp .build/release/gemini-cli /usr/local/bin/

# Or use the release binary
curl -L https://github.com/marcusziade/GeminiKit/releases/latest/download/gemini-cli -o /usr/local/bin/gemini-cli
chmod +x /usr/local/bin/gemini-cli
```

## Quick Start

### SDK Usage

```swift
import GeminiKit

// Initialize
let gemini = GeminiKit(apiKey: "YOUR_API_KEY")

// Generate text
let response = try await gemini.generateContent(
    model: .gemini25Flash,
    prompt: "Explain quantum computing"
)

// Chat session
let chat = gemini.startChat(model: .gemini25Pro)
let reply = try await chat.sendMessage("Hello!")

// Stream responses
let stream = try await chat.streamMessage("Tell me a story")
for try await chunk in stream {
    print(chunk, terminator: "")
}
```

### CLI Usage

```bash
# Set API key
export GEMINI_API_KEY="your-api-key"

# Generate text
gemini-cli generate "Explain AI"

# Interactive chat
gemini-cli chat

# Generate images
gemini-cli generate-image "A sunset over mountains" --count 4

# Analyze video
gemini-cli analyze-video "https://youtube.com/watch?v=..." --prompt "Summarize this"

# Generate speech
gemini-cli generate-speech "Hello world" --voice Zephyr --output speech.wav
```

## CLI Commands

| Command | Description | Example |
|---------|-------------|---------|
| `generate` | Generate text content | `gemini-cli generate "Write a haiku"` |
| `stream` | Stream text generation | `gemini-cli stream "Tell a story"` |
| `chat` | Interactive chat session | `gemini-cli chat` |
| `count` | Count tokens | `gemini-cli count "Test text"` |
| `generate-image` | Create images | `gemini-cli generate-image "A cat" --count 2` |
| `generate-video` | Create videos (paid tier) | `gemini-cli generate-video "Ocean waves" --wait` |
| `analyze-video` | Analyze video content | `gemini-cli analyze-video video.mp4 --transcribe` |
| `generate-speech` | Text-to-speech | `gemini-cli generate-speech "Hello" --voice Lyra` |
| `embeddings` | Generate embeddings | `gemini-cli embeddings "Sample text"` |
| `function-call` | Test function calling | `gemini-cli function-call "What's 15*27?"` |
| `code-execution` | Execute code | `gemini-cli code-execution "Write fibonacci"` |
| `web-grounding` | Search the web | `gemini-cli web-grounding "Latest Swift news"` |

## Advanced Features

### Function Calling

```swift
let weatherFunction = FunctionBuilder(
    name: "get_weather",
    description: "Get weather information"
)
.addString("location", description: "City name", required: true)
.build()

let response = try await gemini.executeWithFunctions(
    model: .gemini25Flash,
    messages: [Content.user("Weather in Tokyo?")],
    functions: [weatherFunction],
    functionHandlers: ["get_weather": { _ in ["temp": 22, "condition": "sunny"] }]
)
```

### Multi-Modal Content

```swift
// Analyze image
let imageData = try Data(contentsOf: imageURL)
let response = try await gemini.generateContent(
    model: .gemini25Flash,
    messages: [Content(role: .user, parts: [
        .text("What's in this image?"),
        .inlineData(InlineData(mimeType: "image/jpeg", data: imageData))
    ])]
)

// Analyze video with metadata
let content = Content(role: .user, parts: [
    .fileData(FileData(mimeType: "video/mp4", fileUri: videoURL)),
    .videoMetadata(VideoMetadata(startOffset: "00:30", endOffset: "01:00")),
    .text("What happens in this clip?")
])
```

### Structured Output

```swift
// JSON mode
let config = GenerationConfig(
    responseMimeType: "application/json",
    responseSchema: ["type": "object", "properties": ["name": ["type": "string"]]]
)

// Enum mode
let enumConfig = GenerationConfig(
    responseMimeType: "text/x.enum",
    responseSchema: ["type": "string", "enum": ["happy", "sad", "neutral"]]
)
```

## Models & Capabilities

### Text Generation
- `gemini-2.5-flash` - Fast, versatile model
- `gemini-2.5-pro` - Advanced reasoning
- `gemini-1.5-flash` - Legacy fast model
- `gemini-1.5-pro` - Legacy advanced model

### Specialized Models
- **Images**: `imagen-3.0-generate-002`
- **Video**: `veo-2.0-generate-001` (paid tier)
- **Speech**: `gemini-2.5-flash-preview-tts`
- **Embeddings**: `text-embedding-004`

## Platform Notes

### Linux
- Uses cURL for true SSE streaming (URLSession on Linux doesn't support streaming)
- Full feature parity with macOS/iOS

### File Upload
- Currently returns "Failed to get upload URL" - API limitation
- Use inline data for files under 20MB
- YouTube URLs work directly for video analysis

## Error Handling

```swift
do {
    let response = try await gemini.generateContent(...)
} catch GeminiError.rateLimitExceeded {
    // Handle rate limit
} catch GeminiError.apiError(let code, let message, _) {
    // Handle API error
} catch {
    // Handle other errors
}
```

## License

MIT License - see [LICENSE](LICENSE) file for details.