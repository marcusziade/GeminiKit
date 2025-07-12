# Getting Started

Learn how to set up and use GeminiKit in your Swift projects.

## Overview

GeminiKit is designed to be easy to integrate and use in your Swift applications. This guide will walk you through the initial setup and basic usage patterns.

## Prerequisites

Before you begin, ensure you have:

- Swift 5.9 or later
- macOS 13+ or Linux with Swift runtime
- A Google Gemini API key ([Get one here](https://makersuite.google.com/app/apikey))

## Basic Setup

### 1. Add the Package

Add GeminiKit to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/guitaripod/GeminiKit", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["GeminiKit"]
)
```

### 2. Import and Initialize

```swift
import GeminiKit

// Create a client instance
let gemini = GeminiKit(apiKey: "your-api-key")

// Or use environment variable
let gemini = GeminiKit() // Reads from GEMINI_API_KEY
```

### 3. Your First Request

```swift
// Simple text generation
let response = try await gemini.generateContent(
    model: .gemini25Flash,
    prompt: "Explain quantum computing in simple terms"
)

if let text = response.candidates?.first?.content.parts.first?.text {
    print(text)
}
```

## Configuration Options

GeminiKit offers extensive configuration options:

```swift
let config = GeminiConfiguration(
    apiKey: "your-api-key",
    baseURL: "https://custom-endpoint.com", // Optional
    timeoutInterval: 120, // Seconds
    maxRetries: 5,
    customHeaders: ["X-Custom": "value"]
)

let gemini = GeminiKit(configuration: config)
```

## Error Handling

Always handle potential errors when making API calls:

```swift
do {
    let response = try await gemini.generateContent(
        model: .gemini25Flash,
        prompt: "Hello, world!"
    )
    // Process response
} catch GeminiError.rateLimitExceeded {
    print("Rate limit exceeded, please retry later")
} catch GeminiError.apiError(let code, let message, _) {
    print("API Error \(code): \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Next Steps

- Explore <doc:TextGeneration> for advanced text generation features
- Learn about <doc:StreamingResponses> for real-time output
- Discover <doc:MultiModalInputs> for working with images and video
- Try <doc:FunctionCalling> for dynamic interactions

## Best Practices

1. **Store API Keys Securely**: Never hard-code API keys in your source code
2. **Handle Rate Limits**: Implement retry logic with exponential backoff
3. **Use Appropriate Models**: Choose models based on your use case and performance needs
4. **Monitor Usage**: Track token usage to manage costs effectively

## Support

If you encounter issues:

- Check the [GitHub Issues](https://github.com/guitaripod/GeminiKit/issues)
- Review the [API Documentation](https://geminikit.dev/docs)
- Join the [Discussions](https://github.com/guitaripod/GeminiKit/discussions)