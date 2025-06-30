# Error Handling

Learn how to handle errors gracefully when using GeminiKit.

## Overview

GeminiKit provides comprehensive error handling with detailed error types, recovery suggestions, and help resources. All errors conform to Swift's `LocalizedError` protocol, providing human-readable descriptions and recovery guidance.

## Error Types

### GeminiError

The primary error type for all GeminiKit operations:

```swift
do {
    let response = try await gemini.generateContent(
        model: .gemini25Flash,
        prompt: "Hello, world!"
    )
} catch let error as GeminiError {
    // Handle specific GeminiKit errors
    print("Error: \(error.errorDescription ?? "")")
    print("Recovery: \(error.recoverySuggestion ?? "")")
    
    if let helpURL = error.helpAnchor {
        print("Learn more: \(helpURL)")
    }
}
```

## Common Error Scenarios

### Authentication Errors

Handle API key and authentication issues:

```swift
do {
    let response = try await gemini.generateContent(...)
} catch GeminiError.invalidAPIKey {
    print("Please check your API key")
    // Prompt user to update API key
} catch GeminiError.authenticationFailed(let details) {
    print("Auth failed: \(details)")
    // Check permissions or regenerate key
}
```

### Rate Limiting

Implement retry logic for rate limits:

```swift
func generateWithRetry(prompt: String, maxAttempts: Int = 3) async throws -> String {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await gemini.generateContent(
                model: .gemini25Flash,
                prompt: prompt
            ).candidates?.first?.content.parts.first?.text ?? ""
        } catch GeminiError.rateLimitExceeded {
            lastError = error
            // Exponential backoff
            let delay = pow(2.0, Double(attempt))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        } catch {
            throw error
        }
    }
    
    throw lastError ?? GeminiError.timeout
}
```

### Content Safety

Handle blocked content gracefully:

```swift
do {
    let response = try await gemini.generateContent(
        model: .gemini25Flash,
        prompt: userInput
    )
    
    // Check prompt feedback
    if let feedback = response.promptFeedback,
       let reason = feedback.blockReason {
        print("Content blocked: \(reason)")
        // Provide user guidance
    }
} catch GeminiError.contentBlocked(let reason) {
    print("Content filtered: \(reason)")
    // Suggest content modifications
}
```

### Network Errors

Handle connection issues:

```swift
do {
    let response = try await gemini.generateContent(...)
} catch GeminiError.networkError(let message) {
    print("Network error: \(message)")
    // Check connectivity
} catch GeminiError.timeout {
    print("Request timed out")
    // Retry with longer timeout or smaller request
} catch GeminiError.connectionFailed(let details) {
    print("Connection failed: \(details)")
    // Check proxy/firewall settings
}
```

### File Operations

Handle file upload errors:

```swift
do {
    let file = try await gemini.uploadFile(
        path: imagePath,
        mimeType: "image/jpeg"
    )
} catch GeminiError.fileTooLarge(let maxSize, let actualSize) {
    print("File too large: \(actualSize) > \(maxSize)")
    // Compress or resize file
} catch GeminiError.unsupportedFileType(let mimeType) {
    print("Unsupported type: \(mimeType)")
    // Convert to supported format
} catch GeminiError.fileError(let message) {
    print("File error: \(message)")
    // Check file permissions
}
```

## Error Recovery Patterns

### Automatic Retry with Backoff

```swift
extension GeminiKit {
    func generateContentWithRetry(
        model: GeminiModel,
        prompt: String,
        maxRetries: Int = 3
    ) async throws -> GenerateContentResponse {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await generateContent(
                    model: model,
                    prompt: prompt
                )
            } catch GeminiError.rateLimitExceeded,
                    GeminiError.timeout,
                    GeminiError.networkError {
                lastError = error
                
                // Calculate backoff delay
                let baseDelay = 1.0
                let maxDelay = 60.0
                let delay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
                
                // Add jitter
                let jitter = Double.random(in: 0...0.3)
                let totalDelay = delay + (delay * jitter)
                
                try await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
            } catch {
                // Don't retry on non-recoverable errors
                throw error
            }
        }
        
        throw lastError ?? GeminiError.timeout
    }
}
```

### Fallback Strategies

```swift
func generateContentWithFallback(prompt: String) async throws -> String {
    do {
        // Try Pro model first
        let response = try await gemini.generateContent(
            model: .gemini25Pro,
            prompt: prompt
        )
        return response.candidates?.first?.content.parts.first?.text ?? ""
    } catch GeminiError.modelNotFound,
            GeminiError.quotaExceeded {
        // Fall back to Flash model
        let response = try await gemini.generateContent(
            model: .gemini25Flash,
            prompt: prompt
        )
        return response.candidates?.first?.content.parts.first?.text ?? ""
    }
}
```

### Circuit Breaker Pattern

```swift
class GeminiCircuitBreaker {
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let threshold = 5
    private let timeout: TimeInterval = 60
    
    var isOpen: Bool {
        guard failureCount >= threshold else { return false }
        guard let lastFailure = lastFailureTime else { return false }
        return Date().timeIntervalSince(lastFailure) < timeout
    }
    
    func recordSuccess() {
        failureCount = 0
        lastFailureTime = nil
    }
    
    func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
    }
    
    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        guard !isOpen else {
            throw GeminiError.networkError("Circuit breaker is open")
        }
        
        do {
            let result = try await operation()
            recordSuccess()
            return result
        } catch {
            recordFailure()
            throw error
        }
    }
}
```

## Best Practices

### 1. Always Handle Errors

Never ignore potential errors:

```swift
// ❌ Bad
let response = try! await gemini.generateContent(...)

// ✅ Good
do {
    let response = try await gemini.generateContent(...)
} catch {
    logger.error("Generation failed: \(error)")
    // Handle appropriately
}
```

### 2. Use Specific Error Types

Match specific errors when possible:

```swift
// ❌ Generic handling
catch {
    print("Something went wrong")
}

// ✅ Specific handling
catch GeminiError.rateLimitExceeded {
    // Implement backoff
} catch GeminiError.invalidAPIKey {
    // Prompt for new key
} catch {
    // Handle unexpected errors
}
```

### 3. Provide User Feedback

Use error properties for helpful messages:

```swift
catch let error as GeminiError {
    // Show user-friendly error
    showAlert(
        title: "Error",
        message: error.errorDescription ?? "Unknown error",
        suggestion: error.recoverySuggestion
    )
}
```

### 4. Log Errors for Debugging

```swift
import os

private let logger = Logger(subsystem: "com.app.gemini", category: "api")

catch let error as GeminiError {
    logger.error("API error: \(error.errorDescription ?? ""), help: \(error.helpAnchor ?? "")")
}
```

### 5. Implement Graceful Degradation

```swift
func getAIResponse(prompt: String) async -> String {
    do {
        let response = try await gemini.generateContent(
            model: .gemini25Flash,
            prompt: prompt
        )
        return response.candidates?.first?.content.parts.first?.text ?? ""
    } catch {
        // Log error but don't crash
        logger.error("AI generation failed: \(error)")
        
        // Return fallback response
        return "I'm having trouble processing that request. Please try again."
    }
}
```

## Testing Error Handling

```swift
import XCTest

class ErrorHandlingTests: XCTestCase {
    func testRateLimitHandling() async throws {
        let mockClient = MockGeminiKit(
            shouldFailWith: .rateLimitExceeded
        )
        
        do {
            _ = try await mockClient.generateContent(
                model: .gemini25Flash,
                prompt: "Test"
            )
            XCTFail("Should have thrown rate limit error")
        } catch GeminiError.rateLimitExceeded {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
```

## See Also

- <doc:GeminiError> - Complete error type reference
- <doc:ConfigurationOptions> - Timeout and retry configuration
- <doc:APIReference> - Full API documentation