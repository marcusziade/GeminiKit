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
    
    func testUnauthorizedError() {
        let error = GeminiError.unauthorized
        
        if case .unauthorized = error {
            // Success
        } else {
            XCTFail("Expected unauthorized error")
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
    
    func testModelNotFoundError() {
        let error = GeminiError.modelNotFound
        
        if case .modelNotFound = error {
            // Success
        } else {
            XCTFail("Expected modelNotFound error")
        }
    }
    
    func testAPIError() {
        let error = GeminiError.apiError(
            code: 500,
            message: "Internal server error",
            details: ["reason": "database_error"]
        )
        
        if case .apiError(let code, let message, let details) = error {
            XCTAssertEqual(code, 500)
            XCTAssertEqual(message, "Internal server error")
            XCTAssertEqual(details?["reason"] as? String, "database_error")
        } else {
            XCTFail("Expected apiError")
        }
    }
    
    func testNetworkError() {
        let underlyingError = NSError(domain: "test", code: -1, userInfo: nil)
        let error = GeminiError.networkError(underlyingError)
        
        if case .networkError(let err) = error {
            XCTAssertEqual((err as NSError).domain, "test")
            XCTAssertEqual((err as NSError).code, -1)
        } else {
            XCTFail("Expected networkError")
        }
    }
    
    func testDecodingError() {
        let error = GeminiError.decodingError("Invalid JSON")
        
        if case .decodingError(let message) = error {
            XCTAssertEqual(message, "Invalid JSON")
        } else {
            XCTFail("Expected decodingError")
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
    
    func testFileNotFoundError() {
        let error = GeminiError.fileNotFound("/path/to/file")
        
        if case .fileNotFound(let path) = error {
            XCTAssertEqual(path, "/path/to/file")
        } else {
            XCTFail("Expected fileNotFound error")
        }
    }
    
    func testFunctionExecutionFailedError() {
        let underlyingError = NSError(domain: "test", code: -1, userInfo: nil)
        let error = GeminiError.functionExecutionFailed("myFunction", underlyingError)
        
        if case .functionExecutionFailed(let name, let err) = error {
            XCTAssertEqual(name, "myFunction")
            XCTAssertEqual((err as NSError).domain, "test")
        } else {
            XCTFail("Expected functionExecutionFailed error")
        }
    }
    
    func testInvalidFunctionResponseError() {
        let error = GeminiError.invalidFunctionResponse
        
        if case .invalidFunctionResponse = error {
            // Success
        } else {
            XCTFail("Expected invalidFunctionResponse error")
        }
    }
    
    func testUnsupportedFeatureError() {
        let error = GeminiError.unsupportedFeature("Streaming on Linux")
        
        if case .unsupportedFeature(let feature) = error {
            XCTAssertEqual(feature, "Streaming on Linux")
        } else {
            XCTFail("Expected unsupportedFeature error")
        }
    }
    
    func testErrorLocalizedDescription() {
        let errors: [(GeminiError, String)] = [
            (.invalidRequest("Bad input"), "Invalid request: Bad input"),
            (.unauthorized, "Unauthorized: Invalid or missing API key"),
            (.rateLimitExceeded, "Rate limit exceeded"),
            (.modelNotFound, "Model not found"),
            (.apiError(code: 404, message: "Not found", details: nil), "API error 404: Not found"),
            (.decodingError("Bad JSON"), "Decoding error: Bad JSON"),
            (.invalidConfiguration("No key"), "Invalid configuration: No key"),
            (.fileNotFound("/tmp/file"), "File not found: /tmp/file"),
            (.invalidFunctionResponse, "Invalid function response"),
            (.unsupportedFeature("Feature X"), "Unsupported feature: Feature X")
        ]
        
        for (error, expectedDescription) in errors {
            XCTAssertEqual(error.localizedDescription, expectedDescription)
        }
    }
}