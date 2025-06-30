import XCTest
@testable import GeminiKit

final class AudioTests: XCTestCase {
    
    func testTTSVoice() {
        // Test some common voices
        XCTAssertEqual(TTSVoice.zephyr.rawValue, "Zephyr")
        XCTAssertEqual(TTSVoice.puck.rawValue, "Puck")
        XCTAssertEqual(TTSVoice.kore.rawValue, "Kore")
        XCTAssertEqual(TTSVoice.charon.rawValue, "Charon")
        XCTAssertEqual(TTSVoice.fenrir.rawValue, "Fenrir")
        
        // Test that all voices can be created
        for voice in TTSVoice.allCases {
            XCTAssertNotNil(voice.rawValue)
            XCTAssertFalse(voice.rawValue.isEmpty)
        }
    }
    
    // Note: TTS request/response types are internal implementation details
    // and not exposed in the public API. The SDK uses TTSVoice enum
    // directly in the generateSpeech method.
}