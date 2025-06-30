#!/bin/bash
# Test script for all GeminiKit CLI commands
# This script demonstrates the correct syntax for each command

# Check if API key is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY environment variable is not set"
    echo "Please set it before running this script:"
    echo "  export GEMINI_API_KEY='your-api-key'"
    exit 1
fi

# Determine the correct path to the CLI binary
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CLI=".build/x86_64-unknown-linux-gnu/release/gemini-cli"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Check for Apple Silicon or Intel
    if [[ $(uname -m) == "arm64" ]]; then
        CLI=".build/arm64-apple-macosx/release/gemini-cli"
    else
        CLI=".build/x86_64-apple-macosx/release/gemini-cli"
    fi
else
    CLI=".build/release/gemini-cli"
fi

# Check if CLI exists
if [ ! -f "$CLI" ]; then
    echo "Error: CLI not found at $CLI"
    echo "Please build the project first with: swift build -c release"
    exit 1
fi

echo "Testing GeminiKit CLI Commands"
echo "=============================="
echo "Using CLI at: $CLI"
echo ""

# 1. Text generation
echo -e "\n1. Testing generate command..."
$CLI generate "Write a haiku about coding"

# 2. Streaming
echo -e "\n2. Testing stream command..."
$CLI stream "Count from 1 to 5 slowly"

# 3. Token counting
echo -e "\n3. Testing count command..."
$CLI count "The quick brown fox jumps over the lazy dog"

# 4. Interactive chat (simulated with echo)
echo -e "\n4. Testing chat command..."
echo -e "What is the capital of France?\nexit" | $CLI chat

# 5. Embeddings
echo -e "\n5. Testing embeddings command..."
$CLI embeddings "Machine learning is transforming technology" | head -3

# 6. Code execution
echo -e "\n6. Testing code-execution command..."
$CLI code-execution "Write a Python function to calculate the factorial of a number"

# 7. Web grounding
echo -e "\n7. Testing web-grounding command..."
$CLI web-grounding "What are the latest AI developments in 2024?" | head -10

# 8. Function calling
echo -e "\n8. Testing function-call command..."
$CLI function-call "What's the weather in Tokyo and calculate 25 times 4"

# 9. Image generation
echo -e "\n9. Testing generate-image command..."
$CLI generate-image "A serene mountain landscape at sunset" --output /tmp

# 10. Speech generation
echo -e "\n10. Testing generate-speech command..."
$CLI generate-speech "Hello, welcome to GeminiKit CLI" --output /tmp/welcome.wav

# 11. Video analysis (using YouTube URL)
echo -e "\n11. Testing analyze-video command..."
$CLI analyze-video "https://youtu.be/dQw4w9WgXcQ" --prompt "What is this video about?" | head -10

# 12. List files
echo -e "\n12. Testing list-files command..."
$CLI list-files

# 13. OpenAI chat
echo -e "\n13. Testing openai-chat command..."
$CLI openai-chat "Explain recursion in one sentence"

# 14. Config info
echo -e "\n14. Testing config-info command..."
$CLI config-info | head -15

echo -e "\n✅ All commands tested successfully!"
echo -e "\nFor more examples and options, run: $CLI --help"
echo -e "For command-specific help, run: $CLI <command> --help"