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

### stream
Stream content generation in real-time.

```bash
gemini-cli stream "Your prompt here" [options]
```

**Known Issue**: JSON decoding error when parsing streaming chunks
- **Problem**: The streaming response format differs from expected structure
- **Debug**: Run with verbose output to see raw response: `gemini-cli stream "prompt" 2>&1`
- **Workaround**: Use non-streaming `generate` command instead

### count
Count tokens in text.

```bash
gemini-cli count "Text to count tokens"
```

### chat
Interactive chat session.

```bash
gemini-cli chat [options]
```

Options:
- `--model`: Model to use
- `-s, --system`: System instruction

### embeddings
Generate text embeddings.

```bash
gemini-cli embeddings "Text to embed" [options]
```

Options:
- `--model`: Embedding model (default: text-embedding-004)

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

### generate-speech
Generate speech from text.

```bash
gemini-cli generate-speech "Text to speak" [options]
```

Options:
- `--model`: TTS model (default: gemini-2.5-flash-preview-tts)
- `-v, --voice`: Voice name (default: Zephyr)
- `-o, --output`: Output file path

### code-execution
Execute code with AI assistance.

```bash
gemini-cli code-execution "Code task description"
```

### web-grounding
Search the web for current information.

```bash
gemini-cli web-grounding "Search query"
```

### function-call
Test function calling capabilities.

```bash
gemini-cli function-call "Task requiring function calls"
```

**Known Issue**: Calculator function parameter validation fails
- **Problem**: The function calling example expects specific parameter format
- **Debug**: The calculator only supports expressions like "2 + 2", not natural language
- **Workaround**: Use direct arithmetic expressions or implement custom functions

### open-ai-chat
OpenAI-compatible chat completion.

```bash
gemini-cli open-ai-chat "Your message" [options]
```

Options:
- `--model`: Model mapping
- `-t, --temperature`: Temperature
- `-m, --max-tokens`: Maximum tokens

### File Operations

#### upload
Upload a file for processing.

```bash
gemini-cli upload <file-path>
```

**Known Issue**: File upload API endpoint not accessible
- **Problem**: The upload endpoint returns 404 or permission denied
- **Debug**: Check API response: `gemini-cli upload file.txt 2>&1`
- **Note**: File uploads may require additional API permissions or different endpoint

#### list-files
List uploaded files.

```bash
gemini-cli list-files
```

#### delete-file
Delete an uploaded file.

```bash
gemini-cli delete-file <file-name>
```

### config-info
Display available models and configuration.

```bash
gemini-cli config-info
```

## Examples

### Basic text generation
```bash
gemini-cli generate "Explain quantum computing"
```

### JSON output
```bash
gemini-cli generate "List 3 benefits of Swift" --format json
```

### With system instruction
```bash
gemini-cli generate "Explain Docker" -s "You are a DevOps expert"
```

### Generate multiple images
```bash
gemini-cli generate-image "A sunset over mountains" -c 4 -r 16:9
```

### Text-to-speech with custom voice
```bash
gemini-cli generate-speech "Hello world" -v Lyra -o speech.wav
```

### Web search
```bash
gemini-cli web-grounding "Latest Swift features"
```

## Known Issues Summary

1. **stream command**: JSON parsing errors due to SSE format differences
2. **function-call command**: Limited to basic calculator operations
3. **upload command**: File API endpoint access issues
4. **chat command**: Interactive mode requires TTY (not tested in scripts)

## Debugging Tips

- Redirect stderr to see full error details: `command 2>&1`
- Use `--help` on any command for detailed options
- Check the API reference file for endpoint specifications
- Enable verbose logging by setting `GEMINI_DEBUG=true`

## Exit Codes

- 0: Success
- 1: Error (invalid input, API error, etc.)