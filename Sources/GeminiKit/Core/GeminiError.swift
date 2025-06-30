import Foundation

/// Errors that can occur when using GeminiKit.
///
/// `GeminiError` provides comprehensive error information including detailed descriptions,
/// recovery suggestions, and help resources for handling failures gracefully.
///
/// ## Topics
///
/// ### Authentication Errors
/// - ``invalidAPIKey``
/// - ``authenticationFailed(_:)``
///
/// ### Configuration Errors
/// - ``invalidConfiguration(_:)``
/// - ``missingRequiredParameter(_:)``
///
/// ### Network Errors
/// - ``networkError(_:)``
/// - ``timeout``
/// - ``connectionFailed(_:)``
///
/// ### API Errors
/// - ``apiError(code:message:details:)``
/// - ``rateLimitExceeded``
/// - ``quotaExceeded``
/// - ``modelNotFound(_:)``
/// - ``invalidModel(_:)``
///
/// ### Request Errors
/// - ``invalidRequest(_:)``
/// - ``contentBlocked(reason:)``
/// - ``functionExecutionFailed(name:error:)``
/// - ``invalidFunctionResponse``
///
/// ### File Operation Errors
/// - ``fileError(_:)``
/// - ``fileTooLarge(maxSize:actualSize:)``
/// - ``unsupportedFileType(mimeType:)``
///
/// ### Streaming Errors
/// - ``streamingError(_:)``
/// - ``streamInterrupted``
///
/// ### Platform Errors
/// - ``unsupportedPlatform(_:)``
/// - ``unsupportedFeature(_:)``
///
/// ## Example
///
/// ```swift
/// do {
///     let response = try await gemini.generateContent(...)
/// } catch let error as GeminiError {
///     print("Error: \(error.errorDescription ?? "")")
///     print("Recovery: \(error.recoverySuggestion ?? "")")
///     
///     if let helpURL = error.helpAnchor {
///         print("More info: \(helpURL)")
///     }
/// }
/// ```
public enum GeminiError: LocalizedError, Equatable, Sendable {
    /// Invalid API key provided
    case invalidAPIKey
    
    /// Authentication failed with additional context
    case authenticationFailed(String)
    
    /// Invalid configuration
    case invalidConfiguration(String)
    
    /// Missing required parameter
    case missingRequiredParameter(String)
    
    /// Network error
    case networkError(String)
    
    /// Connection failed
    case connectionFailed(String)
    
    /// Invalid response from server
    case invalidResponse(String)
    
    /// API error from server
    case apiError(code: Int, message: String, details: String?)
    
    /// Rate limit exceeded
    case rateLimitExceeded
    
    /// Quota exceeded
    case quotaExceeded
    
    /// Model not found
    case modelNotFound(String)
    
    /// Invalid model specified
    case invalidModel(String)
    
    /// Request timeout
    case timeout
    
    /// Invalid request
    case invalidRequest(String)
    
    /// Content blocked by safety filters
    case contentBlocked(reason: String)
    
    /// Function execution failed
    case functionExecutionFailed(name: String, error: String)
    
    /// Invalid function response
    case invalidFunctionResponse
    
    /// File operation error
    case fileError(String)
    
    /// File too large
    case fileTooLarge(maxSize: Int, actualSize: Int)
    
    /// Unsupported file type
    case unsupportedFileType(mimeType: String)
    
    /// Streaming error
    case streamingError(String)
    
    /// Stream interrupted
    case streamInterrupted
    
    /// Unsupported platform
    case unsupportedPlatform(String)
    
    /// Unsupported feature
    case unsupportedFeature(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key provided. The API key is either missing, malformed, or has been revoked."
        case .authenticationFailed(let details):
            return "Authentication failed: \(details)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .missingRequiredParameter(let parameter):
            return "Missing required parameter: '\(parameter)'"
        case .networkError(let message):
            return "Network error: \(message)"
        case .connectionFailed(let details):
            return "Failed to establish connection: \(details)"
        case .invalidResponse(let message):
            return "Invalid response from server: \(message)"
        case .apiError(let code, let message, let details):
            var description = "API error \(code): \(message)"
            if let details = details {
                description += "\nDetails: \(details)"
            }
            return description
        case .rateLimitExceeded:
            return "Rate limit exceeded. Too many requests in a short time period."
        case .quotaExceeded:
            return "API quota exceeded. You have reached your usage limit."
        case .modelNotFound(let model):
            return "Model '\(model)' not found or not accessible with your API key."
        case .invalidModel(let model):
            return "Invalid model specified: '\(model)'"
        case .timeout:
            return "Request timed out. The server did not respond within the timeout period."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .contentBlocked(let reason):
            return "Content blocked by safety filters: \(reason)"
        case .functionExecutionFailed(let name, let error):
            return "Function '\(name)' execution failed: \(error)"
        case .invalidFunctionResponse:
            return "Function returned an invalid response format"
        case .fileError(let message):
            return "File operation error: \(message)"
        case .fileTooLarge(let maxSize, let actualSize):
            return "File too large. Maximum size: \(maxSize) bytes, actual size: \(actualSize) bytes"
        case .unsupportedFileType(let mimeType):
            return "Unsupported file type: \(mimeType)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .streamInterrupted:
            return "Stream was interrupted unexpectedly"
        case .unsupportedPlatform(let message):
            return "Unsupported platform: \(message)"
        case .unsupportedFeature(let feature):
            return "Feature '\(feature)' is not supported in this configuration"
        }
    }
    
    /// Suggestion for recovering from the error
    public var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey:
            return "Verify your API key is correct and active. You can get a new key from https://makersuite.google.com/app/apikey"
        case .authenticationFailed:
            return "Check your API key and ensure it has the necessary permissions for the requested operation."
        case .invalidConfiguration:
            return "Review your configuration settings and ensure all required fields are properly set."
        case .missingRequiredParameter(let parameter):
            return "Add the required parameter '\(parameter)' to your request."
        case .networkError:
            return "Check your internet connection and try again. If the problem persists, the service may be temporarily unavailable."
        case .connectionFailed:
            return "Verify your network settings, proxy configuration, and firewall rules. Ensure the Gemini API endpoints are accessible."
        case .invalidResponse:
            return "This may be a temporary issue. Try again in a few moments. If the problem persists, check for service status updates."
        case .apiError(let code, _, _):
            switch code {
            case 400:
                return "Review your request parameters and ensure they meet the API requirements."
            case 401:
                return "Verify your API key is valid and properly configured."
            case 403:
                return "Ensure your API key has permission to access this resource or feature."
            case 404:
                return "Check that the endpoint, model, or resource exists and is spelled correctly."
            case 429:
                return "You're making requests too quickly. Implement exponential backoff and retry after a delay."
            case 500...599:
                return "This is a server error. Wait a moment and try again. If it persists, check the service status."
            default:
                return "Review the error details and adjust your request accordingly."
            }
        case .rateLimitExceeded:
            return "Implement rate limiting in your application. Wait at least 60 seconds before retrying. Consider upgrading your plan for higher limits."
        case .quotaExceeded:
            return "You've reached your usage limit. Check your usage in the Google Cloud Console and consider upgrading your plan."
        case .modelNotFound:
            return "Verify the model name is correct. Use one of the available models like .gemini25Flash or .gemini25Pro"
        case .invalidModel:
            return "Check the model name spelling and ensure it's a supported model for your API key tier."
        case .timeout:
            return "Try reducing the request size or complexity. Consider using streaming for long-running operations."
        case .invalidRequest:
            return "Review the request format and parameters according to the API documentation."
        case .contentBlocked:
            return "Modify your prompt to avoid sensitive content. Review the safety settings and adjust thresholds if appropriate."
        case .functionExecutionFailed:
            return "Check your function implementation for errors. Ensure it returns data in the expected format."
        case .invalidFunctionResponse:
            return "Ensure your function returns a valid JSON-serializable response."
        case .fileError:
            return "Verify the file exists, is accessible, and you have the necessary permissions."
        case .fileTooLarge(let maxSize, _):
            return "Reduce the file size to under \(maxSize) bytes or use a different file."
        case .unsupportedFileType(_):
            return "Convert the file to a supported format. Supported types include: image/jpeg, image/png, video/mp4, audio/mp3, etc."
        case .streamingError:
            return "Check your connection stability. For large responses, ensure your timeout settings are appropriate."
        case .streamInterrupted:
            return "The stream was interrupted. Try establishing a new streaming connection."
        case .unsupportedPlatform:
            return "This feature requires a different platform or OS version. Check the documentation for platform requirements."
        case .unsupportedFeature:
            return "This feature may require a different model or API configuration. Check the feature compatibility matrix."
        }
    }
    
    /// URL for additional help about this error
    public var helpAnchor: String? {
        switch self {
        case .invalidAPIKey, .authenticationFailed:
            return "https://ai.google.dev/tutorials/setup"
        case .rateLimitExceeded, .quotaExceeded:
            return "https://ai.google.dev/pricing"
        case .modelNotFound, .invalidModel:
            return "https://ai.google.dev/models/gemini"
        case .contentBlocked:
            return "https://ai.google.dev/gemini-api/docs/safety-settings"
        case .functionExecutionFailed, .invalidFunctionResponse:
            return "https://ai.google.dev/gemini-api/docs/function-calling"
        case .fileTooLarge, .unsupportedFileType:
            return "https://ai.google.dev/gemini-api/docs/prompting_with_media"
        default:
            return "https://ai.google.dev/gemini-api/docs/troubleshooting"
        }
    }
}