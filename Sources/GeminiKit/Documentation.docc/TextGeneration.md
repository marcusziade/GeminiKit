# Text Generation

Generate text content using Gemini models with various configuration options.

## Overview

Text generation is the core feature of GeminiKit, supporting everything from simple prompts to complex multi-turn conversations with system instructions, safety settings, and response constraints.

## Basic Text Generation

### Simple Generation

```swift
let response = try await gemini.generateContent(
    model: .gemini25Flash,
    prompt: "Write a haiku about programming"
)

print(response.candidates?.first?.content.parts.first?.text ?? "")
```

### With System Instructions

```swift
let response = try await gemini.generateContent(
    model: .gemini25Pro,
    messages: [
        Content.user("Explain recursion")
    ],
    systemInstruction: Content.system("You are a computer science professor. Explain concepts clearly with examples.")
)
```

## Generation Configuration

Control generation behavior with `GenerationConfig`:

```swift
let config = GenerationConfig(
    temperature: 0.7,           // Creativity (0-2)
    topP: 0.95,                // Nucleus sampling
    topK: 40,                  // Top-k sampling
    maxOutputTokens: 1024,     // Response length limit
    stopSequences: ["END"],    // Stop generation triggers
    presencePenalty: 0.0,      // Penalize repeated topics (-2 to 2)
    frequencyPenalty: 0.0,     // Penalize repeated words (-2 to 2)
    responseLogprobs: true,    // Include log probabilities
    logprobs: 5               // Number of top logprobs
)

let response = try await gemini.generateContent(
    model: .gemini25Flash,
    prompt: "Write a story",
    generationConfig: config
)
```

## Response Formats

### JSON Mode

Force responses in valid JSON format:

```swift
let config = GenerationConfig(
    responseMimeType: "application/json",
    responseSchema: .object(
        properties: [
            "name": .string(enum: nil),
            "age": .integer,
            "skills": .array(items: .string(enum: nil))
        ],
        required: ["name", "age"]
    )
)

let response = try await gemini.generateContent(
    model: .gemini25Flash,
    prompt: "Generate a character profile",
    generationConfig: config
)
```

### Structured Output

Define exact response schemas:

```swift
let schema = ResponseSchema.object(
    properties: [
        "recipe": .object(
            properties: [
                "title": .string(enum: nil),
                "ingredients": .array(
                    items: .object(
                        properties: [
                            "name": .string(enum: nil),
                            "amount": .string(enum: nil)
                        ],
                        required: ["name", "amount"]
                    )
                ),
                "instructions": .array(items: .string(enum: nil)),
                "cookTime": .integer
            ],
            required: ["title", "ingredients", "instructions"]
        )
    ],
    required: ["recipe"]
)

let config = GenerationConfig(
    responseMimeType: "application/json",
    responseSchema: schema
)
```

## Multi-Turn Conversations

Create stateful chat sessions:

```swift
// Start a chat
let chat = gemini.startChat(
    model: .gemini25Pro,
    systemInstruction: "You are a helpful coding assistant"
)

// First message
let response1 = try await chat.sendMessage("What is Swift?")

// Follow-up with context
let response2 = try await chat.sendMessage("What are its main features?")

// Access full history
let history = chat.history
```

## Safety Settings

Configure content safety thresholds:

```swift
let safetySettings = [
    SafetySetting(
        category: .harassment,
        threshold: .blockMediumAndAbove
    ),
    SafetySetting(
        category: .hateSpeech,
        threshold: .blockOnlyHigh
    ),
    SafetySetting(
        category: .sexuallyExplicit,
        threshold: .blockMediumAndAbove
    ),
    SafetySetting(
        category: .dangerousContent,
        threshold: .blockLowAndAbove
    )
]

let response = try await gemini.generateContent(
    model: .gemini25Flash,
    prompt: "Generate content",
    safetySettings: safetySettings
)
```

## Advanced Features

### Thinking Mode

Enable step-by-step reasoning:

```swift
let response = try await gemini.generateContent(
    model: .gemini25Pro,
    prompt: "Solve this logic puzzle: ...",
    generationConfig: GenerationConfig(thinkingBudget: 8192)
)

// Access thinking process
if let thinking = response.candidates?.first?.content.parts.first(where: { 
    if case .thinking = $0 { return true }
    return false
}) {
    print("Reasoning:", thinking)
}
```

### Token Management

Count tokens before generation:

```swift
let countResponse = try await gemini.countTokens(
    model: .gemini25Flash,
    messages: [
        Content.user("This is my prompt")
    ]
)

print("Input tokens: \(countResponse.totalTokens)")
```

## Best Practices

1. **Choose the Right Model**: Use Flash models for speed, Pro models for complex reasoning
2. **Set Temperature Appropriately**: Lower for factual tasks (0.2-0.5), higher for creative tasks (0.7-1.5)
3. **Use System Instructions**: Provide clear context for consistent behavior
4. **Handle Safety Blocks**: Check `response.promptFeedback` for blocked content
5. **Optimize Token Usage**: Use `maxOutputTokens` to control costs

## Error Handling

Handle generation-specific errors:

```swift
do {
    let response = try await gemini.generateContent(...)
    
    // Check for safety blocks
    if let feedback = response.promptFeedback,
       feedback.blockReason != nil {
        print("Content blocked: \(feedback.blockReason!)")
    }
    
} catch GeminiError.invalidRequest(let message) {
    print("Invalid request: \(message)")
} catch GeminiError.modelNotFound {
    print("Model not available")
}
```

## See Also

- <doc:StreamingResponses> - Real-time text generation
- <doc:ChatConversations> - Multi-turn conversations
- <doc:ThinkingMode> - Step-by-step reasoning