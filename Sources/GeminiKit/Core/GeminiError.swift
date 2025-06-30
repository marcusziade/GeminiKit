import Foundation

/// Errors that can occur when using GeminiKit
public enum GeminiError: LocalizedError, Equatable, Sendable {
    /// Invalid API key
    case invalidAPIKey
    
    /// Invalid configuration
    case invalidConfiguration(String)
    
    /// Network error
    case networkError(String)
    
    /// Invalid response from server
    case invalidResponse(String)
    
    /// API error from server
    case apiError(code: Int, message: String, details: String?)
    
    /// Rate limit exceeded
    case rateLimitExceeded
    
    /// Request timeout
    case timeout
    
    /// Invalid request
    case invalidRequest(String)
    
    /// File operation error
    case fileError(String)
    
    /// Streaming error
    case streamingError(String)
    
    /// Unsupported platform
    case unsupportedPlatform(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key provided"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .apiError(let code, let message, let details):
            var description = "API error \(code): \(message)"
            if let details = details {
                description += " - \(details)"
            }
            return description
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .timeout:
            return "Request timed out"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .fileError(let message):
            return "File error: \(message)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .unsupportedPlatform(let message):
            return "Unsupported platform: \(message)"
        }
    }
}