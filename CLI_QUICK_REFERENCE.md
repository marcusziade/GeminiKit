# GeminiKit CLI Quick Reference

## Setup
```bash
export GEMINI_API_KEY="your-api-key"  # Set once per session
```

## Text Commands
```bash
gemini-cli generate "prompt"           # Generate text
gemini-cli stream "prompt"             # Stream text
gemini-cli chat                        # Interactive chat
gemini-cli count "text"                # Count tokens
```

## Media Generation
```bash
gemini-cli generate-image "prompt"     # Generate images
gemini-cli generate-video "prompt"     # Generate videos (paid)
gemini-cli generate-speech "text"      # Text-to-speech
```

## Analysis
```bash
gemini-cli analyze-video "video.mp4"   # Analyze video
gemini-cli analyze-video "youtube.com/..." # Analyze YouTube
gemini-cli embeddings "text"           # Generate embeddings
```

## Advanced
```bash
gemini-cli function-call "prompt"      # Function calling
gemini-cli code-execution "prompt"     # Execute code
gemini-cli web-grounding "prompt"      # Web search
gemini-cli openai-chat "message"       # OpenAI mode
```

## Files
```bash
gemini-cli upload file.pdf             # Upload file
gemini-cli list-files                  # List files
gemini-cli delete-file "name"          # Delete file
```

## Common Options
```bash
--api-key "key"                        # Override API key
--model gemini-2.5-pro                 # Change model
--help                                 # Get help
```

## Help
```bash
gemini-cli --help                      # Main help
gemini-cli <command> --help            # Command help
gemini-cli config-info                 # Show models/voices
```