# GeminiKit CLI Reference

## Overview

The GeminiKit CLI (`gemini-cli`) is a command-line tool for testing and interacting with the Gemini API through the GeminiKit Swift SDK.

## API Reference

The implementation is based on the Gemini API reference located at:
```
/home/marcus/Dev/python/gemini_api_reference.json
```

## Installation

```bash
swift build -c release --product gemini-cli
```

The binary will be available at `.build/release/gemini-cli`

## Authentication

Set your API key as an environment variable:
```bash
export GEMINI_API_KEY="your-api-key"
```

Or pass it directly to commands:
```bash
gemini-cli generate "Hello" --api-key "your-api-key"
```

**Note**: All commands support the `--api-key` option for direct API key specification.

## Commands

### generate
Generate text content from a prompt.

```bash
gemini-cli generate "Your prompt here" [options]
```

Options:
- `--model`: Model to use (default: gemini-2.5-flash)
- `-s, --system`: System instruction
- `-t, --temperature`: Temperature (0.0-2.0)
- `-m, --max-tokens`: Maximum output tokens
- `--format`: Output format (text/json)

**Status**: ✅ Working

### stream
Stream content generation in real-time.

```bash
gemini-cli stream "Your prompt here" [options]
```

**Status**: ✅ Working - Uses process-based cURL on Linux for true SSE streaming

### count
Count tokens in text.

```bash
gemini-cli count "Text to count tokens"
```

**Status**: ✅ Working

### chat
Interactive chat session.

```bash
gemini-cli chat [options]
```

Options:
- `--model`: Model to use
- `-s, --system`: System instruction

**Status**: ✅ Working (requires TTY for interactive mode)

**Note**: For scripted use, pipe input through stdin:
```bash
echo "Your message" | gemini-cli chat
```

### embeddings
Generate text embeddings.

```bash
gemini-cli embeddings "Text to embed" [options]
```

Options:
- `--model`: Embedding model (default: text-embedding-004)

**Status**: ✅ Working

### generate-image
Generate images from text prompts.

```bash
gemini-cli generate-image "Image description" [options]
```

Options:
- `--model`: Image model (default: imagen-3.0-generate-002)
- `-c, --count`: Number of images (1-4)
- `-r, --ratio`: Aspect ratio (1:1, 16:9, 9:16, 4:3)
- `-o, --output`: Output directory

**Status**: ✅ Working

### generate-speech
Generate speech from text.

```bash
gemini-cli generate-speech "Text to speak" [options]
```

Options:
- `--model`: TTS model (default: gemini-2.5-flash-preview-tts)
- `-v, --voice`: Voice name (default: Zephyr)
- `-o, --output`: Output file path

**Status**: ✅ Working

### code-execution
Execute code with AI assistance.

```bash
gemini-cli code-execution "Code task description"
```

**Status**: ✅ Working

### web-grounding
Search the web for current information.

```bash
gemini-cli web-grounding "Search query"
```

**Status**: ✅ Working

### function-call
Test function calling capabilities.

```bash
gemini-cli function-call "Task requiring function calls"
```

**Status**: ✅ Working

Built-in functions:
- **Calculator**: Performs arithmetic operations (add, subtract, multiply, divide)
- **Weather**: Returns mock weather data for any location

### open-ai-chat
OpenAI-compatible chat completion.

```bash
gemini-cli open-ai-chat "Your message" [options]
```

Options:
- `--model`: Model mapping
- `-t, --temperature`: Temperature
- `-m, --max-tokens`: Maximum tokens

**Status**: ✅ Working

### File Operations

#### upload
Upload a file for processing.

```bash
gemini-cli upload <file-path>
```

**Status**: ❌ Not Working
- **Issue**: Returns "Failed to get upload URL"
- **Reason**: The Gemini API file upload requires different authentication or API configuration
- **Note**: This appears to be an API limitation rather than an SDK issue

#### list-files
List uploaded files.

```bash
gemini-cli list-files
```

**Status**: ✅ Working (returns empty list as no files can be uploaded)

#### delete-file
Delete an uploaded file.

```bash
gemini-cli delete-file <file-name>
```

**Status**: ⚠️ Untested (requires working file upload)

### config-info
Display available models and configuration.

```bash
gemini-cli config-info
```

**Status**: ✅ Working

## Examples

### Basic text generation
```bash
gemini-cli generate "Explain quantum computing"
# Output: Quantum computing harnesses the principles of quantum mechanics...
```

### JSON output
```bash
gemini-cli generate "List 3 benefits of Swift" --format json
# Output: {"response":"1. Type safety..."}
```

### With system instruction
```bash
gemini-cli generate "Explain Docker" -s "You are a DevOps expert"
# Output: As a DevOps expert, I can tell you that Docker is...
```

### Streaming responses
```bash
gemini-cli stream "Write a haiku about programming"
# Output: Code flows line by line,
#         Bugs appear, then they are fixed,
#         New worlds start to live.
```

### Count tokens
```bash
gemini-cli count "This is a test text to count tokens"
# Output: Total tokens: 9
```

### Generate embeddings
```bash
gemini-cli embeddings "Hello world"
# Output: Embedding dimensions: 768
#         First 10 values: 0.0132, -0.0087, -0.0468...
```

### Generate multiple images
```bash
gemini-cli generate-image "A sunset over mountains" -c 4 -r 16:9 -o ./images
# Output: Images saved:
#         - ./images/image_1.png
#         - ./images/image_2.png
#         - ./images/image_3.png
#         - ./images/image_4.png
```

### Text-to-speech with custom voice
```bash
gemini-cli generate-speech "Hello world" -v Lyra -o speech.wav
# Output: Audio saved to: speech.wav
```

### Code execution
```bash
gemini-cli code-execution "Write a Python script that calculates fibonacci numbers"
# Output: [Complete Python script with fibonacci implementation]
```

### Web search
```bash
gemini-cli web-grounding "What is the latest version of Swift?"
# Output: The latest stable version of Swift is 6.1.2...
#         Web searches:
#         - latest stable version of Swift
#         Sources:
#         - wikipedia.org: https://...
#         - swift.org: https://...
```

### Function calling
```bash
gemini-cli function-call "Calculate 15 times 27"
# Output: The result of multiplying 15 and 27 is 405.

gemini-cli function-call "What's the weather in Tokyo?"
# Output: The weather in Tokyo is rainy with a temperature of 60 degrees...
```

### OpenAI-compatible chat
```bash
gemini-cli open-ai-chat "Hello, how are you?"
# Output: Hello! I am functioning perfectly and ready to assist you...
#         ---
#         Tokens - Prompt: 7, Completion: 24, Total: 31
```

## Command Status Summary

| Command | Status | Notes |
|---------|--------|-------|
| generate | ✅ Working | Full text generation with all options |
| stream | ✅ Working | True SSE streaming via cURL on Linux |
| count | ✅ Working | Token counting |
| chat | ✅ Working | Interactive mode requires TTY |
| embeddings | ✅ Working | Text embeddings generation |
| generate-image | ✅ Working | Image generation with multiple options |
| generate-speech | ✅ Working | Text-to-speech with voice selection |
| code-execution | ✅ Working | AI-assisted code generation |
| web-grounding | ✅ Working | Web search integration |
| function-call | ✅ Working | Function calling with calculator and weather |
| open-ai-chat | ✅ Working | OpenAI-compatible interface |
| config-info | ✅ Working | Model and configuration display |
| list-files | ✅ Working | Lists uploaded files (empty) |
| upload | ❌ Not Working | API limitation - "Failed to get upload URL" |
| delete-file | ⚠️ Untested | Requires working file upload |

## Architecture Notes

### Linux Streaming Implementation
On Linux, the SDK uses a process-based cURL implementation for true SSE streaming support:
- Spawns a cURL process with `-N` flag for no buffering
- Reads output incrementally from the process pipe
- Parses SSE events in real-time with proper buffering
- Thread-safe handling using Swift actors

### Platform Differences
- **macOS/iOS**: Uses native URLSession streaming
- **Linux**: Uses cURL process for true streaming (URLSession on Linux doesn't support streaming)

## Debugging Tips

- Redirect stderr to see full error details: `command 2>&1`
- Use `--help` on any command for detailed options
- Check the API reference file for endpoint specifications
- Enable verbose logging by setting `GEMINI_DEBUG=true` (currently minimal debug output)
- On Linux, the SDK uses a process-based cURL implementation for true SSE streaming support

## Exit Codes

- 0: Success
- 1: Error (invalid input, API error, etc.)