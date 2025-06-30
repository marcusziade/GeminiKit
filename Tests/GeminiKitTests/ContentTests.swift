import XCTest
@testable import GeminiKit

final class ContentTests: XCTestCase {
    
    func testUserContent() {
        let content = Content.user("Hello, world!")
        
        XCTAssertEqual(content.role, .user)
        XCTAssertEqual(content.parts.count, 1)
        
        if case .text(let text) = content.parts[0] {
            XCTAssertEqual(text, "Hello, world!")
        } else {
            XCTFail("Expected text part")
        }
    }
    
    func testModelContent() {
        let content = Content.model("I'm a helpful assistant")
        
        XCTAssertEqual(content.role, .model)
        XCTAssertEqual(content.parts.count, 1)
        
        if case .text(let text) = content.parts[0] {
            XCTAssertEqual(text, "I'm a helpful assistant")
        } else {
            XCTFail("Expected text part")
        }
    }
    
    func testSystemContent() {
        let content = Content.system("You are a coding expert")
        
        XCTAssertEqual(content.role, .system)
        XCTAssertEqual(content.parts.count, 1)
        
        if case .text(let text) = content.parts[0] {
            XCTAssertEqual(text, "You are a coding expert")
        } else {
            XCTFail("Expected text part")
        }
    }
    
    func testMultiPartContent() {
        let imageData = Data("fake-image".utf8)
        let content = Content(
            role: .user,
            parts: [
                .text("What's in this image?"),
                .inlineData(InlineData(mimeType: "image/jpeg", data: imageData))
            ]
        )
        
        XCTAssertEqual(content.role, .user)
        XCTAssertEqual(content.parts.count, 2)
        
        if case .text(let text) = content.parts[0] {
            XCTAssertEqual(text, "What's in this image?")
        } else {
            XCTFail("Expected text part")
        }
        
        if case .inlineData(let inlineData) = content.parts[1] {
            XCTAssertEqual(inlineData.mimeType, "image/jpeg")
            XCTAssertEqual(inlineData.data, imageData.base64EncodedString())
        } else {
            XCTFail("Expected inline data part")
        }
    }
    
    func testFunctionContent() {
        let response = FunctionResponse(
            name: "get_weather",
            response: ["temperature": AnyCodable(72), "condition": AnyCodable("sunny")]
        )
        let content = Content(
            role: .model,
            parts: [.functionResponse(response)]
        )
        
        XCTAssertEqual(content.role, .model)
        XCTAssertEqual(content.parts.count, 1)
        
        if case .functionResponse(let funcResponse) = content.parts[0] {
            XCTAssertEqual(funcResponse.name, "get_weather")
            XCTAssertNotNil(funcResponse.response["temperature"])
            XCTAssertNotNil(funcResponse.response["condition"])
        } else {
            XCTFail("Expected function response part")
        }
    }
    
    func testContentCodable() throws {
        let original = Content(
            role: .user,
            parts: [
                .text("Hello"),
                .functionCall(FunctionCall(name: "test", args: ["key": AnyCodable("value")]))
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Content.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
}