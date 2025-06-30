import XCTest
@testable import GeminiKit

final class ConfigurationTests: XCTestCase {
    
    func testInitializationWithAPIKey() {
        let apiKey = "test-api-key"
        let config = GeminiConfiguration(apiKey: apiKey)
        
        XCTAssertEqual(config.apiKey, apiKey)
        XCTAssertEqual(config.baseURL, "https://generativelanguage.googleapis.com/v1beta")
        XCTAssertEqual(config.uploadBaseURL, "https://generativelanguage.googleapis.com/upload/v1beta")
        XCTAssertEqual(config.openAIBaseURL, "https://generativelanguage.googleapis.com/v1beta/openai")
        XCTAssertEqual(config.timeoutInterval, 60)
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertTrue(config.customHeaders.isEmpty)
    }
    
    func testInitializationWithCustomValues() {
        let config = GeminiConfiguration(
            apiKey: "custom-key",
            baseURL: "https://custom.endpoint.com",
            uploadBaseURL: "https://custom.upload.com",
            openAIBaseURL: "https://custom.openai.com",
            timeoutInterval: 120,
            maxRetries: 5,
            customHeaders: ["X-Custom": "value"]
        )
        
        XCTAssertEqual(config.apiKey, "custom-key")
        XCTAssertEqual(config.baseURL, "https://custom.endpoint.com")
        XCTAssertEqual(config.uploadBaseURL, "https://custom.upload.com")
        XCTAssertEqual(config.openAIBaseURL, "https://custom.openai.com")
        XCTAssertEqual(config.timeoutInterval, 120)
        XCTAssertEqual(config.maxRetries, 5)
        XCTAssertEqual(config.customHeaders["X-Custom"], "value")
    }
    
    func testFromEnvironment() {
        // Set environment variables
        setenv("GEMINI_API_KEY", "env-api-key", 1)
        setenv("GEMINI_BASE_URL", "https://env.endpoint.com", 1)
        
        let config = GeminiConfiguration.fromEnvironment()
        
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.apiKey, "env-api-key")
        XCTAssertEqual(config?.baseURL, "https://env.endpoint.com")
        
        // Clean up
        unsetenv("GEMINI_API_KEY")
        unsetenv("GEMINI_BASE_URL")
    }
    
    func testFromEnvironmentMissingAPIKey() {
        // Ensure API key is not set
        unsetenv("GEMINI_API_KEY")
        
        let config = GeminiConfiguration.fromEnvironment()
        
        XCTAssertNil(config)
    }
    
    func testDefaultHeaders() {
        let config = GeminiConfiguration(apiKey: "test-key")
        let headers = config.defaultHeaders
        
        XCTAssertEqual(headers["x-goog-api-key"], "test-key")
        XCTAssertTrue(headers["User-Agent"]?.contains("GeminiKit") ?? false)
    }
}