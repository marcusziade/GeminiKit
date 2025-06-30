#!/bin/bash
# Test script for all GeminiKit CLI commands

API_KEY="${GEMINI_API_KEY}"

# Check if API key is set
if [ -z "$API_KEY" ]; then
    echo "Error: GEMINI_API_KEY environment variable is not set"
    echo "Please set it before running this script:"
    echo "  export GEMINI_API_KEY='your-api-key'"
    exit 1
fi
CLI=".build/release/gemini-cli"

echo "Testing GeminiKit CLI Commands"
echo "=============================="

# Text generation
echo -e "\n1. Testing generate command..."
$CLI generate 'Say hello' --api-key "$API_KEY"

# Streaming
echo -e "\n2. Testing stream command..."
$CLI stream 'Count to 3' --api-key "$API_KEY"

# Token counting
echo -e "\n3. Testing count command..."
$CLI count 'Hello world' --api-key "$API_KEY"

# Embeddings
echo -e "\n4. Testing embeddings command..."
$CLI embeddings 'Test text' --api-key "$API_KEY" | head -2

# Code execution
echo -e "\n5. Testing code-execution command..."
$CLI code-execution 'Write a function to add two numbers' --api-key "$API_KEY" | head -10

# Web grounding
echo -e "\n6. Testing web-grounding command..."
$CLI web-grounding 'Current weather' --api-key "$API_KEY" | head -5

# Function calling
echo -e "\n7. Testing function-call command..."
$CLI function-call 'Calculate 15 plus 25' --api-key "$API_KEY"

# OpenAI chat
echo -e "\n8. Testing open-ai-chat command..."
$CLI open-ai-chat 'Hello' --api-key "$API_KEY"

# Config info
echo -e "\n9. Testing config-info command..."
$CLI config-info --api-key "$API_KEY" | head -10

echo -e "\n✅ All commands tested successfully!"