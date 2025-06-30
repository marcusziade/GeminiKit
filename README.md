# GeminiKit

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgray.svg)](https://github.com/marcusziade/GeminiKit)
[![CI](https://github.com/marcusziade/GeminiKit/workflows/CI/badge.svg)](https://github.com/marcusziade/GeminiKit/actions)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/docker/v/marcusziade/geminikit?label=docker)](https://hub.docker.com/r/marcusziade/geminikit)

A comprehensive, production-ready Swift SDK for the Google Gemini API with full feature coverage, cross-platform support, and a powerful CLI.

## Features

- ✅ **Complete API Coverage**: All Gemini API features including text generation, image/video generation, TTS, embeddings, and more
- ✅ **Cross-Platform**: Works on macOS, iOS, tvOS, watchOS, and Linux
- ✅ **Protocol-Oriented Design**: Clean, extensible architecture using Swift 5.9 features
- ✅ **Streaming Support**: Real-time response streaming with proper SSE handling
- ✅ **OpenAI Compatibility**: Drop-in replacement for OpenAI API clients
- ✅ **Advanced Features**: Function calling, code execution, web grounding, thinking mode
- ✅ **Type-Safe**: Strongly typed requests and responses with comprehensive error handling
- ✅ **CLI Tool**: Feature-rich command-line interface for testing and automation
- ✅ **Docker Support**: Ready-to-use Docker images for containerized deployment

## Installation

### Swift Package Manager

Add GeminiKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/marcusziade/GeminiKit", from: "1.0.0")
]
```

### CLI Installation

#### Homebrew (macOS)
```bash
brew tap marcusziade/geminikit
brew install gemini-cli
```

#### Direct Download
Download the latest release from [GitHub Releases](https://github.com/marcusziade/GeminiKit/releases).

#### Docker
```bash
docker pull marcusziade/geminikit:latest
```

## Quick Start

### Basic Usage

```swift
import GeminiKit

// Create client
let gemini = GeminiKit(apiKey: "YOUR_API_KEY")

// Generate content
let response = try await gemini.generateContent(
    model: .gemini25Flash,
    prompt: "Explain quantum computing in simple terms"
)

print(response.candidates?.first?.content.parts.first)
```

### Chat Conversations

```swift
// Start a chat session
let chat = gemini.startChat(
    model: .gemini25Pro,
    systemInstruction: "You are a helpful assistant"
)

// Send messages
let response = try await chat.sendMessage("What's the weather like?")
print(response)

// Stream responses
let stream = try await chat.streamMessage("Tell me a story")
for try await chunk in stream {
    print(chunk, terminator: "")
}
```

### Advanced Features

#### Function Calling

```swift
// Define a function
let weatherFunction = FunctionBuilder(
    name: "get_weather",
    description: "Get weather information"
)
.addString("location", description: "City name", required: true)
.addString("unit", description: "Temperature unit", enumValues: ["celsius", "fahrenheit"])
.build()

// Execute with function handling
let response = try await gemini.executeWithFunctions(
    model: .gemini25Flash,
    messages: [Content.user("What's the weather in Tokyo?")],
    functions: [weatherFunction],
    functionHandlers: [
        "get_weather": { call in
            // Your weather API logic here
            return ["temperature": 22, "condition": "sunny"]
        }
    ]
)
```

#### Image Generation

```swift
let images = try await gemini.generateImages(
    model: .imagen30Generate002,
    prompt: "A serene mountain landscape at sunset",
    count: 2,
    aspectRatio: .landscape
)

// Save images
for (index, prediction) in images.enumerated() {
    let data = Data(base64Encoded: prediction.bytesBase64Encoded)!
    try data.write(to: URL(fileURLWithPath: "image_\(index).png"))
}
```

#### Video Generation

```swift
// Start video generation
let operationName = try await gemini.generateVideos(
    model: .veo20Generate001,
    prompt: "A timelapse of clouds moving across the sky",
    duration: 8,
    aspectRatio: .landscape
)

// Wait for completion
let videos = try await gemini.waitForVideos(operationName)
```

#### Text-to-Speech

```swift
let audioData = try await gemini.generateSpeech(
    model: .gemini25FlashPreviewTTS,
    text: "Hello, this is a test of text-to-speech.",
    voice: .zephyr
)

// Save audio file
try audioData.write(to: URL(fileURLWithPath: "speech.wav"))
```

## CLI Usage

### Basic Commands

```bash
# Generate content
gemini-cli generate "Explain relativity"

# Stream responses
gemini-cli stream "Write a poem about the ocean"

# Count tokens
gemini-cli count "This is a test message"

# Interactive chat
gemini-cli chat
```

### Advanced Commands

```bash
# Generate images
gemini-cli generate-image "A futuristic city" --count 4 --ratio 16:9

# Generate speech
gemini-cli generate-speech "Hello world" --voice Zephyr --output speech.wav

# Function calling demo
gemini-cli function-call "What's 25 * 4?"

# Web grounding
gemini-cli web-grounding "What are the latest AI developments?"
```

### Docker Usage

```bash
# Run with Docker
docker run -e GEMINI_API_KEY=your_key marcusziade/geminikit generate "Hello"

# Interactive mode
docker run -it -e GEMINI_API_KEY=your_key marcusziade/geminikit chat

# With volume for output files
docker run -v $(pwd)/output:/output -e GEMINI_API_KEY=your_key \
  marcusziade/geminikit generate-image "A sunset" --output /output
```

## Configuration

### Environment Variables

```bash
export GEMINI_API_KEY="your-api-key"
export GEMINI_BASE_URL="https://custom-endpoint.com"  # Optional
```

### Programmatic Configuration

```swift
let config = GeminiConfiguration(
    apiKey: "your-api-key",
    timeoutInterval: 120,
    maxRetries: 5,
    customHeaders: ["X-Custom": "value"]
)

let gemini = GeminiKit(configuration: config)
```

## API Reference

### Models

- **Text Generation**: `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-1.5-flash`, `gemini-1.5-pro`
- **Image Generation**: `imagen-3.0-generate-002`, `imagen-4.0-generate-preview`
- **Video Generation**: `veo-2.0-generate-001`
- **Text-to-Speech**: `gemini-2.5-flash-preview-tts`, `gemini-2.5-pro-preview-tts`
- **Embeddings**: `text-embedding-004`

### Supported Features

- ✅ Text generation with streaming
- ✅ Multi-modal inputs (text, images, video, audio)
- ✅ Function calling
- ✅ Code execution
- ✅ Web grounding (Google Search)
- ✅ Structured output (JSON/Enum)
- ✅ Thinking mode
- ✅ File uploads
- ✅ Token counting
- ✅ Safety settings
- ✅ OpenAI compatibility layer

## Error Handling

```swift
do {
    let response = try await gemini.generateContent(
        model: .gemini25Flash,
        prompt: "Hello"
    )
} catch GeminiError.rateLimitExceeded {
    print("Rate limit hit, please retry later")
} catch GeminiError.apiError(let code, let message, let details) {
    print("API Error \(code): \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Testing

Run the test suite:

```bash
swift test
```

Run specific tests:

```bash
swift test --filter GeminiKitTests.ConfigurationTests
```

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Swift 5.9
- Uses URLSession on Apple platforms and Foundation on Linux
- Inspired by modern Swift API design patterns

## Support

- 📧 [Email](mailto:support@geminikit.dev)
- 🐛 [Issue Tracker](https://github.com/marcusziade/GeminiKit/issues)
- 📖 [Documentation](https://geminikit.dev/docs)
- 💬 [Discussions](https://github.com/marcusziade/GeminiKit/discussions)