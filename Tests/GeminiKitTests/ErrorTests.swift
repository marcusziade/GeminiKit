import XCTest
@testable import GeminiKit

final class ErrorTests: XCTestCase {
    
    func testInvalidRequestError() {
        let error = GeminiError.invalidRequest("Missing required field")
        
        if case .invalidRequest(let message) = error {
            XCTAssertEqual(message, "Missing required field")
        } else {
            XCTFail("Expected invalidRequest error")
        }
    }
    
    func testInvalidAPIKeyError() {
        let error = GeminiError.invalidAPIKey
        
        if case .invalidAPIKey = error {
            // Success
        } else {
            XCTFail("Expected invalidAPIKey error")
        }
    }
    
    func testRateLimitExceededError() {
        let error = GeminiError.rateLimitExceeded
        
        if case .rateLimitExceeded = error {
            // Success
        } else {
            XCTFail("Expected rateLimitExceeded error")
        }
    }
    
    func testTimeoutError() {
        let error = GeminiError.timeout
        
        if case .timeout = error {
            // Success
        } else {
            XCTFail("Expected timeout error")
        }
    }
    
    func testAPIError() {
        let error = GeminiError.apiError(
            code: 500,
            message: "Internal server error",
            details: "database_error"
        )
        
        if case .apiError(let code, let message, let details) = error {
            XCTAssertEqual(code, 500)
            XCTAssertEqual(message, "Internal server error")
            XCTAssertEqual(details, "database_error")
        } else {
            XCTFail("Expected apiError")
        }
    }
    
    func testNetworkError() {
        let error = GeminiError.networkError("Connection failed")
        
        if case .networkError(let message) = error {
            XCTAssertEqual(message, "Connection failed")
        } else {
            XCTFail("Expected networkError")
        }
    }
    
    func testInvalidResponseError() {
        let error = GeminiError.invalidResponse("Invalid JSON")
        
        if case .invalidResponse(let message) = error {
            XCTAssertEqual(message, "Invalid JSON")
        } else {
            XCTFail("Expected invalidResponse")
        }
    }
    
    func testInvalidConfigurationError() {
        let error = GeminiError.invalidConfiguration("API key missing")
        
        if case .invalidConfiguration(let message) = error {
            XCTAssertEqual(message, "API key missing")
        } else {
            XCTFail("Expected invalidConfiguration error")
        }
    }
    
    func testFileError() {
        let error = GeminiError.fileError("File not found: /path/to/file")
        
        if case .fileError(let message) = error {
            XCTAssertEqual(message, "File not found: /path/to/file")
        } else {
            XCTFail("Expected fileError")
        }
    }
    
    func testStreamingError() {
        let error = GeminiError.streamingError("Stream interrupted")
        
        if case .streamingError(let message) = error {
            XCTAssertEqual(message, "Stream interrupted")
        } else {
            XCTFail("Expected streamingError")
        }
    }
    
    func testUnsupportedPlatformError() {
        let error = GeminiError.unsupportedPlatform("Linux streaming")
        
        if case .unsupportedPlatform(let message) = error {
            XCTAssertEqual(message, "Linux streaming")
        } else {
            XCTFail("Expected unsupportedPlatform error")
        }
    }
    
    // Removed testUnsupportedFeatureError as it doesn't exist in GeminiError
    
    func testErrorLocalizedDescription() {
        let errors: [(GeminiError, String)] = [
            (.invalidRequest("Bad input"), "Invalid request: Bad input"),
            (.invalidAPIKey, "Invalid API key provided. The API key is either missing, malformed, or has been revoked."),
            (.rateLimitExceeded, "Rate limit exceeded. Too many requests in a short time period."),
            (.timeout, "Request timed out. The server did not respond within the timeout period."),
            (.apiError(code: 404, message: "Not found", details: nil), "API error 404: Not found"),
            (.invalidResponse("Bad JSON"), "Invalid response from server: Bad JSON"),
            (.invalidConfiguration("No key"), "Invalid configuration: No key"),
            (.fileError("/tmp/file"), "File operation error: /tmp/file"),
            (.streamingError("Error"), "Streaming error: Error"),
            (.unsupportedPlatform("Platform X"), "Unsupported platform: Platform X")
        ]
        
        for (error, expectedDescription) in errors {
            XCTAssertEqual(error.localizedDescription, expectedDescription)
        }
    }
}