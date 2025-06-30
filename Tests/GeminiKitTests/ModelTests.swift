import XCTest
@testable import GeminiKit

final class ModelTests: XCTestCase {
    
    func testGeminiModelRawValues() {
        XCTAssertEqual(GeminiModel.gemini25Flash.rawValue, "gemini-2.5-flash")
        XCTAssertEqual(GeminiModel.gemini25Pro.rawValue, "gemini-2.5-pro")
        XCTAssertEqual(GeminiModel.gemini25FlashLite.rawValue, "gemini-2.5-flash-lite")
        XCTAssertEqual(GeminiModel.gemini20Flash.rawValue, "gemini-2.0-flash")
        XCTAssertEqual(GeminiModel.gemini15Flash.rawValue, "gemini-1.5-flash")
        XCTAssertEqual(GeminiModel.gemini15Pro.rawValue, "gemini-1.5-pro")
    }
    
    func testSpecializedModelRawValues() {
        // Image generation models
        XCTAssertEqual(GeminiModel.imagen30Generate002.rawValue, "imagen-3.0-generate-002")
        XCTAssertEqual(GeminiModel.imagen40GeneratePreview.rawValue, "imagen-4.0-generate-preview-06-06")
        
        // Video generation models
        XCTAssertEqual(GeminiModel.veo20Generate001.rawValue, "veo-2.0-generate-001")
        
        // TTS models
        XCTAssertEqual(GeminiModel.gemini25FlashPreviewTTS.rawValue, "gemini-2.5-flash-preview-tts")
        XCTAssertEqual(GeminiModel.gemini25ProPreviewTTS.rawValue, "gemini-2.5-pro-preview-tts")
        
        // Embedding model
        XCTAssertEqual(GeminiModel.textEmbedding004.rawValue, "text-embedding-004")
    }
    
    func testModelCapabilities() {
        let flash = GeminiModel.gemini25Flash
        let pro = GeminiModel.gemini25Pro
        
        // Both should support common capabilities
        XCTAssertEqual(flash.rawValue, "gemini-2.5-flash")
        XCTAssertEqual(pro.rawValue, "gemini-2.5-pro")
        
        // Test model capabilities
        XCTAssertTrue(flash.supportsThinking)
        XCTAssertTrue(pro.supportsThinking)
        XCTAssertFalse(GeminiModel.gemini15Flash.supportsThinking)
    }
    
    func testResponseModalities() {
        XCTAssertEqual(ResponseModality.text.rawValue, "TEXT")
        XCTAssertEqual(ResponseModality.image.rawValue, "IMAGE")
        XCTAssertEqual(ResponseModality.audio.rawValue, "AUDIO")
    }
}