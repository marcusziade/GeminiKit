# GeminiKit CLI Complete Guide

This guide provides comprehensive documentation for all GeminiKit CLI commands with examples and tips.

## Table of Contents
- [Installation](#installation)
- [Configuration](#configuration)
- [Command Reference](#command-reference)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

## Installation

### From Source
```bash
# Clone the repository
git clone https://github.com/marcusziade/GeminiKit.git
cd GeminiKit

# Build the CLI
swift build -c release --product gemini-cli

# Install to system (optional)
sudo cp .build/release/gemini-cli /usr/local/bin/
```

### Path to Built Binary
After building, the CLI binary is located at:
- Linux: `.build/x86_64-unknown-linux-gnu/release/gemini-cli`
- macOS: `.build/arm64-apple-macosx/release/gemini-cli` or `.build/x86_64-apple-macosx/release/gemini-cli`

## Configuration

### API Key Setup
You can provide your API key in three ways:

1. **Environment Variable (Recommended)**
   ```bash
   export GEMINI_API_KEY="your-api-key-here"
   ```

2. **Command Line Option**
   ```bash
   gemini-cli generate "Hello" --api-key "your-api-key-here"
   ```

3. **Configuration File**
   Create a `.env` file in your project directory:
   ```
   GEMINI_API_KEY=your-api-key-here
   ```

### Default Model
The default model is `gemini-2.5-flash`. You can change it for any command:
```bash
gemini-cli generate "Hello" --model gemini-2.5-pro
```

## Command Reference

### Text Generation Commands

#### `generate` - Generate text content
**Syntax:** `gemini-cli generate <prompt> [options]`

**Options:**
- `--system, -s <string>` - System instruction to guide the model
- `--temperature, -t <number>` - Creativity level (0.0-2.0, default: 1.0)
- `--max-tokens, -m <number>` - Maximum tokens to generate
- `--format <string>` - Output format: text, json, or markdown (default: text)

**Examples:**
```bash
# Simple generation
gemini-cli generate "Write a haiku about programming"

# With system instruction
gemini-cli generate "Explain Docker" --system "You are a DevOps expert"

# JSON output with temperature control
gemini-cli generate "List 5 programming languages with descriptions" \
  --format json \
  --temperature 0.5

# Limited output length
gemini-cli generate "Summarize quantum computing" --max-tokens 100
```

#### `stream` - Stream text generation
**Syntax:** `gemini-cli stream <prompt> [options]`

**Options:**
- `--system, -s <string>` - System instruction

**Examples:**
```bash
# Watch the response appear in real-time
gemini-cli stream "Tell me a story about a robot"

# Streaming with persona
gemini-cli stream "Explain recursion" \
  --system "You are a patient computer science teacher"
```

#### `chat` - Interactive chat session
**Syntax:** `gemini-cli chat [options]`

**Options:**
- `--system, -s <string>` - System instruction for the chat session

**Usage:**
- Type your messages and press Enter
- Type `exit` to quit the chat
- Conversation history is maintained during the session

**Examples:**
```bash
# Start a general chat
gemini-cli chat

# Chat with a specific persona
gemini-cli chat --system "You are a helpful coding assistant specializing in Swift"
```

#### `count` - Count tokens
**Syntax:** `gemini-cli count <text>`

**Examples:**
```bash
# Count tokens in a sentence
gemini-cli count "The quick brown fox jumps over the lazy dog"

# Count tokens in a longer text
gemini-cli count "$(cat article.txt)"
```

### Multimodal Generation Commands

#### `generate-image` - Create images
**Syntax:** `gemini-cli generate-image <prompt> [options]`

**Options:**
- `--count, -c <number>` - Number of images to generate (1-4, default: 1)
- `--ratio, -r <string>` - Aspect ratio: 1:1, 3:4, 4:3, 9:16, 16:9 (default: 1:1)
- `--output, -o <string>` - Output directory path (default: current directory)
- `--negative <string>` - Things to avoid in the image

**Examples:**
```bash
# Single image
gemini-cli generate-image "A serene mountain landscape at sunrise"

# Multiple variations
gemini-cli generate-image "Modern office interior" \
  --count 4 \
  --ratio 16:9 \
  --output ./designs

# With negative prompt
gemini-cli generate-image "Portrait of a cat" \
  --negative "cartoon, animated, blurry" \
  --ratio 3:4
```

#### `generate-video` - Create videos
**Syntax:** `gemini-cli generate-video <prompt> [options]`

**Options:**
- `--duration, -d <number>` - Video length in seconds: 5 or 8 (default: 5)
- `--ratio, -r <string>` - Aspect ratio: 16:9 or 9:16 (default: 16:9)
- `--image <string>` - Source image for image-to-video generation
- `--wait` - Wait for video generation to complete

**Examples:**
```bash
# Text-to-video
gemini-cli generate-video "Timelapse of clouds moving over mountains" --wait

# Vertical video for social media
gemini-cli generate-video "Neon lights in a cyberpunk city" \
  --ratio 9:16 \
  --duration 8 \
  --wait

# Image-to-video
gemini-cli generate-video "Bring this scene to life with gentle movement" \
  --image landscape.jpg \
  --wait
```

#### `analyze-video` - Analyze video content
**Syntax:** `gemini-cli analyze-video <video> [options]`

**Options:**
- `--prompt, -p <string>` - Analysis prompt (default: "Please describe this video in detail.")
- `--system <string>` - System instruction
- `--start <string>` - Start time in MM:SS format
- `--end <string>` - End time in MM:SS format
- `--fps <number>` - Frames per second to analyze (default: 1)
- `--transcribe` - Include audio transcription

**Examples:**
```bash
# Analyze entire video
gemini-cli analyze-video presentation.mp4 \
  --prompt "Summarize the key points"

# Analyze YouTube video
gemini-cli analyze-video "https://youtu.be/dQw4w9WgXcQ" \
  --prompt "What is happening in this video?"

# Analyze specific segment with transcription
gemini-cli analyze-video lecture.mp4 \
  --start 05:30 \
  --end 10:45 \
  --transcribe \
  --prompt "Extract the main concepts discussed"

# Frame-by-frame analysis
gemini-cli analyze-video action_scene.mp4 \
  --fps 5 \
  --prompt "Describe the action sequence"
```

#### `generate-speech` - Text-to-speech
**Syntax:** `gemini-cli generate-speech <text> [options]`

**Options:**
- `--voice, -v <string>` - Voice name (default: Zephyr)
- `--output, -o <string>` - Output file path (default: speech.wav)

**Available Voices:**
Aoede, Callirrhoe, Charon, Elektra, Fenrir, Kore, Leona, Leda, Orea, Orion, Perseus, Puck, Sage, Stella, Vale, Vega, Zephyr, and more

**Examples:**
```bash
# Basic TTS
gemini-cli generate-speech "Welcome to our presentation"

# With specific voice and output
gemini-cli generate-speech "Once upon a time" \
  --voice Sage \
  --output story_intro.wav

# Multiple voices for dialogue
gemini-cli generate-speech "Hello, how are you?" --voice Zephyr --output greeting1.wav
gemini-cli generate-speech "I'm doing great, thanks!" --voice Aoede --output greeting2.wav
```

### Advanced Feature Commands

#### `embeddings` - Generate text embeddings
**Syntax:** `gemini-cli embeddings <text>`

**Examples:**
```bash
# Single text embedding
gemini-cli embeddings "Artificial intelligence and machine learning"

# Embed file content
gemini-cli embeddings "$(cat document.txt)"
```

#### `function-call` - Test function calling
**Syntax:** `gemini-cli function-call <prompt>`

**Built-in Functions:**
- Calculator: Basic arithmetic operations
- Weather: Get weather information (mock data)

**Examples:**
```bash
# Math calculations
gemini-cli function-call "What is 15 multiplied by 27?"
gemini-cli function-call "Calculate the square root of 144"

# Weather queries
gemini-cli function-call "What's the weather like in Paris?"
gemini-cli function-call "Tell me the temperature in Tokyo and New York"

# Combined queries
gemini-cli function-call "If it's 20°C in London, what's that in Fahrenheit?"
```

#### `code-execution` - Generate and execute code
**Syntax:** `gemini-cli code-execution <prompt>`

**Examples:**
```bash
# Simple function
gemini-cli code-execution "Write a function to reverse a string"

# With test cases
gemini-cli code-execution "Create a prime number checker and test it with examples"

# Algorithm implementation
gemini-cli code-execution "Implement quicksort and demonstrate it sorting an array"

# Data processing
gemini-cli code-execution "Write code to parse CSV data and calculate statistics"
```

#### `web-grounding` - Web search integration
**Syntax:** `gemini-cli web-grounding <prompt>`

**Examples:**
```bash
# Current events
gemini-cli web-grounding "What are the latest developments in renewable energy?"

# Real-time information
gemini-cli web-grounding "Current Bitcoin price and market analysis"

# Research queries
gemini-cli web-grounding "Recent scientific breakthroughs in quantum computing 2024"

# Fact checking
gemini-cli web-grounding "What is the current population of Tokyo?"
```

### File Management Commands

#### `upload` - Upload files
**Syntax:** `gemini-cli upload <file-path> [options]`

**Options:**
- `--name, -n <string>` - Display name for the file

**Examples:**
```bash
# Upload a document
gemini-cli upload report.pdf

# Upload with custom name
gemini-cli upload screenshot.png --name "UI mockup v2"
```

#### `list-files` - List uploaded files
**Syntax:** `gemini-cli list-files`

**Example:**
```bash
gemini-cli list-files
```

#### `delete-file` - Delete uploaded files
**Syntax:** `gemini-cli delete-file <name>`

**Example:**
```bash
# First list files to get the resource name
gemini-cli list-files

# Then delete using the resource name
gemini-cli delete-file "files/abc123xyz789"
```

### Utility Commands

#### `openai-chat` - OpenAI-compatible interface
**Syntax:** `gemini-cli openai-chat <message> [options]`

**Options:**
- `--system, -s <string>` - System message
- `--stream` - Enable streaming output

**Examples:**
```bash
# Simple query
gemini-cli openai-chat "Explain the concept of recursion"

# With system message
gemini-cli openai-chat "Write a function to validate email addresses" \
  --system "You are an expert Python developer"

# Streaming response
gemini-cli openai-chat "Tell me about the history of computing" --stream
```

#### `config-info` - Display configuration
**Syntax:** `gemini-cli config-info`

Shows:
- Available models and their capabilities
- Context window sizes
- Special features (thinking, image generation, etc.)
- Available TTS voices

**Example:**
```bash
gemini-cli config-info
```

## Common Patterns

### Piping and Input Redirection
```bash
# Analyze file content
cat article.txt | xargs -0 gemini-cli generate "Summarize this text:"

# Process command output
ls -la | xargs -0 gemini-cli generate "Explain this directory structure:"

# Embed multiple texts
for file in *.txt; do
  echo "Processing $file"
  gemini-cli embeddings "$(cat $file)" > "$file.embedding"
done
```

### Batch Processing
```bash
# Generate multiple images
for prompt in "sunrise" "sunset" "midnight"; do
  gemini-cli generate-image "Beautiful $prompt landscape" \
    --output "./images/$prompt"
done

# Convert multiple texts to speech
while IFS= read -r line; do
  gemini-cli generate-speech "$line" --output "line_$RANDOM.wav"
done < script.txt
```

### Output Processing
```bash
# Extract JSON data
gemini-cli generate "List 5 colors with hex codes" --format json | jq '.'

# Save formatted output
gemini-cli generate "Write a README template" --format markdown > README_template.md

# Chain commands
gemini-cli generate "Write a joke" | \
  gemini-cli generate-speech --output joke.wav
```

## Troubleshooting

### Common Issues

1. **"API key not found" error**
   - Ensure GEMINI_API_KEY is exported: `echo $GEMINI_API_KEY`
   - Check for typos in the environment variable name
   - Try passing the key directly: `--api-key "your-key"`

2. **"Model not available" error**
   - Use `gemini-cli config-info` to see available models
   - Some models require specific API tier access

3. **"File upload failed" error**
   - File uploads may have size limitations
   - For videos, consider using YouTube URLs instead
   - Ensure file path is correct and file exists

4. **Streaming not working**
   - On Linux, streaming uses cURL for proper SSE support
   - Ensure your network doesn't block SSE connections

5. **Token limit exceeded**
   - Use `gemini-cli count` to check your input size
   - Consider using `--max-tokens` to limit output
   - Break large inputs into smaller chunks

### Debug Mode
Set verbose output for debugging:
```bash
# Add --verbose flag (if implemented in your version)
gemini-cli generate "Hello" --verbose

# Or use shell debugging
bash -x gemini-cli generate "Hello"
```

### Getting Help
```bash
# General help
gemini-cli --help

# Command-specific help
gemini-cli generate --help
gemini-cli analyze-video --help

# Version information
gemini-cli --version
```

## Best Practices

1. **API Key Security**
   - Never commit API keys to version control
   - Use environment variables or secure key stores
   - Rotate keys regularly

2. **Model Selection**
   - Use `gemini-2.5-flash` for fast, general tasks
   - Use `gemini-2.5-pro` for complex reasoning
   - Check model capabilities with `config-info`

3. **Prompt Engineering**
   - Be specific and clear in your prompts
   - Use system instructions to set context
   - Experiment with temperature for creativity

4. **Resource Management**
   - Clean up uploaded files when done
   - Monitor token usage for cost control
   - Use appropriate models for each task

5. **Error Handling**
   - Always check command output for errors
   - Use exit codes in scripts
   - Implement retries for network issues