# GeminiKit

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgray.svg)](https://github.com/guitaripod/GeminiKit)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI Status](https://github.com/guitaripod/GeminiKit/workflows/CI/badge.svg)](https://github.com/guitaripod/GeminiKit/actions)
[![Release](https://img.shields.io/github/v/release/guitaripod/GeminiKit)](https://github.com/guitaripod/GeminiKit/releases)

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
    .package(url: "https://github.com/guitaripod/GeminiKit", from: "1.0.0")
]
```

### CLI
```bash
# Build from source
swift build -c release --product gemini-cli
cp .build/release/gemini-cli /usr/local/bin/

# Or download the release binary
# macOS:
curl -L https://github.com/guitaripod/GeminiKit/releases/latest/download/gemini-cli-macos.tar.gz | tar xz
sudo mv gemini-cli-macos /usr/local/bin/gemini-cli

# Linux:
curl -L https://github.com/guitaripod/GeminiKit/releases/latest/download/gemini-cli-linux.tar.gz | tar xz
sudo mv gemini-cli-linux /usr/local/bin/gemini-cli
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
# Set API key (required for all commands)
export GEMINI_API_KEY="your-api-key"

# Or pass it directly
gemini-cli generate "Explain AI" --api-key "your-api-key"

# Get help for any command
gemini-cli --help
gemini-cli generate --help
```

## CLI Commands Reference

### Text Generation

#### `generate` - Generate text content
```bash
# Basic usage
gemini-cli generate "Write a haiku about coding"

# With options
gemini-cli generate "Explain quantum computing" \
  --model gemini-2.5-pro \
  --system "You are a physics professor" \
  --temperature 0.7 \
  --max-tokens 500 \
  --format json
```

#### `stream` - Stream text generation in real-time
```bash
# Basic streaming
gemini-cli stream "Tell me a story about space"

# With system instruction
gemini-cli stream "Explain relativity" --system "Explain like I'm 5"
```

#### `chat` - Interactive chat session
```bash
# Start chat (type 'exit' to quit)
gemini-cli chat

# With system instruction
gemini-cli chat --system "You are a helpful coding assistant"
```

#### `count` - Count tokens in text
```bash
gemini-cli count "This is my text to analyze"
```

### Multimodal Generation

#### `generate-image` - Create images from text
```bash
# Single image
gemini-cli generate-image "A futuristic city at sunset"

# Multiple images with options
gemini-cli generate-image "A cat playing piano" \
  --count 4 \
  --ratio 16:9 \
  --output ./images \
  --negative "blurry, low quality"
```

#### `generate-video` - Create videos (requires paid tier)
```bash
# Basic video generation
gemini-cli generate-video "Waves crashing on a beach" --wait

# With options
gemini-cli generate-video "Time-lapse of flowers blooming" \
  --duration 8 \
  --ratio 9:16 \
  --wait

# Image-to-video
gemini-cli generate-video "Make this image move" \
  --image sunset.jpg \
  --wait
```

#### `analyze-video` - Analyze video content
```bash
# Analyze local video
gemini-cli analyze-video video.mp4 \
  --prompt "What happens in this video?"

# Analyze YouTube video
gemini-cli analyze-video "https://youtube.com/watch?v=VIDEO_ID" \
  --prompt "Summarize the main points"

# With time range and transcription
gemini-cli analyze-video video.mp4 \
  --start 00:30 \
  --end 01:45 \
  --fps 2 \
  --transcribe
```

#### `generate-speech` - Text-to-speech conversion
```bash
# Basic TTS
gemini-cli generate-speech "Hello, world!"

# With voice selection and output
gemini-cli generate-speech "Welcome to our podcast" \
  --voice Aoede \
  --output welcome.wav
```

### Advanced Features

#### `embeddings` - Generate text embeddings
```bash
gemini-cli embeddings "Machine learning is transforming technology"
```

#### `function-call` - Test function calling
```bash
# Built-in calculator and weather functions
gemini-cli function-call "What's the weather in Tokyo?"
gemini-cli function-call "Calculate 25 * 4"
```

#### `code-execution` - Generate and execute code
```bash
gemini-cli code-execution "Write a Python function to calculate factorial"
gemini-cli code-execution "Create a sorting algorithm and test it"
```

#### `web-grounding` - Search the web for current information
```bash
gemini-cli web-grounding "Latest developments in quantum computing 2024"
gemini-cli web-grounding "Current stock price of Apple"
```

### File Management

#### `upload` - Upload files to Gemini
```bash
# Upload with auto-generated name
gemini-cli upload document.pdf

# Upload with custom name
gemini-cli upload image.jpg --name "Product screenshot"
```

#### `list-files` - List uploaded files
```bash
gemini-cli list-files
```

#### `delete-file` - Delete uploaded files
```bash
# Delete by resource name (from list-files output)
gemini-cli delete-file "files/abc123xyz"
```

### Utility Commands

#### `openai-chat` - OpenAI-compatible chat
```bash
# Basic chat
gemini-cli openai-chat "Explain recursion"

# Streaming with system message
gemini-cli openai-chat "Write a poem" \
  --system "You are a creative writer" \
  --stream
```

#### `config-info` - Show available models and voices
```bash
gemini-cli config-info
```

## Common Options

All commands support these options:
- `--api-key, -a` - API key (defaults to GEMINI_API_KEY env var)
- `--model` - Model to use (default: gemini-2.5-flash)
- `--help, -h` - Show help for any command

## Examples by Use Case

### Content Creation
```bash
# Blog post outline
gemini-cli generate "Create an outline for a blog post about sustainable living" \
  --format markdown

# Social media content
gemini-cli generate "Write 5 tweet variations about our new product launch" \
  --temperature 1.2

# Image for article
gemini-cli generate-image "Minimalist illustration of renewable energy" \
  --ratio 16:9
```

### Development
```bash
# Code review
gemini-cli generate "Review this Python code for best practices: [paste code]"

# Generate tests
gemini-cli code-execution "Write unit tests for a fibonacci function"

# API documentation
gemini-cli generate "Create OpenAPI spec for a user management API" \
  --format json
```

### Research
```bash
# Current events
gemini-cli web-grounding "Latest AI research breakthroughs 2024"

# Data analysis
gemini-cli generate "Analyze these sales figures and identify trends: [data]" \
  --model gemini-2.5-pro

# Video summary
gemini-cli analyze-video "https://youtube.com/watch?v=..." \
  --prompt "Extract key points and create a summary"
```

### Creative Projects
```bash
# Story writing
gemini-cli stream "Write a sci-fi short story about time travel" \
  --model gemini-2.5-pro

# Voice narration
gemini-cli generate-speech "Once upon a time in a digital world..." \
  --voice Charon \
  --output narration.wav

# Visual content
gemini-cli generate-image "Abstract representation of artificial intelligence" \
  --count 4 \
  --ratio 1:1
```

## Documentation

- **[API Documentation](https://guitaripod.github.io/GeminiKit/documentation/geminikit/)** - Full SDK API reference (DocC)
- **[CLI Complete Guide](CLI_GUIDE.md)** - Comprehensive CLI documentation with all commands, options, and examples
- **[CLI Quick Reference](CLI_QUICK_REFERENCE.md)** - Quick command reference card
- **[Test Script](test-all-commands.sh)** - Example script demonstrating all CLI commands

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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.