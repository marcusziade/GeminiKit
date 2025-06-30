import XCTest
@testable import GeminiKit

final class SafetySettingsTests: XCTestCase {
    
    func testSafetyCategories() {
        XCTAssertEqual(HarmCategory.harassment.rawValue, "HARM_CATEGORY_HARASSMENT")
        XCTAssertEqual(HarmCategory.hateSpeech.rawValue, "HARM_CATEGORY_HATE_SPEECH")
        XCTAssertEqual(HarmCategory.sexuallyExplicit.rawValue, "HARM_CATEGORY_SEXUALLY_EXPLICIT")
        XCTAssertEqual(HarmCategory.dangerousContent.rawValue, "HARM_CATEGORY_DANGEROUS_CONTENT")
    }
    
    func testHarmBlockThresholds() {
        XCTAssertEqual(HarmBlockThreshold.blockNone.rawValue, "BLOCK_NONE")
        XCTAssertEqual(HarmBlockThreshold.blockOnlyHigh.rawValue, "BLOCK_ONLY_HIGH")
        XCTAssertEqual(HarmBlockThreshold.blockMediumAndAbove.rawValue, "BLOCK_MEDIUM_AND_ABOVE")
        XCTAssertEqual(HarmBlockThreshold.blockLowAndAbove.rawValue, "BLOCK_LOW_AND_ABOVE")
    }
    
    func testSafetySettingCreation() {
        let setting = SafetySetting(
            category: .harassment,
            threshold: .blockMediumAndAbove
        )
        
        XCTAssertEqual(setting.category, .harassment)
        XCTAssertEqual(setting.threshold, .blockMediumAndAbove)
    }
    
    func testSafetySettingsCodable() throws {
        let original = SafetySetting(
            category: .dangerousContent,
            threshold: .blockOnlyHigh
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SafetySetting.self, from: data)
        
        XCTAssertEqual(original.category, decoded.category)
        XCTAssertEqual(original.threshold, decoded.threshold)
    }
    
    func testDefaultSafetySettings() {
        let settings = [
            SafetySetting(category: .harassment, threshold: .blockMediumAndAbove),
            SafetySetting(category: .hateSpeech, threshold: .blockMediumAndAbove),
            SafetySetting(category: .sexuallyExplicit, threshold: .blockMediumAndAbove),
            SafetySetting(category: .dangerousContent, threshold: .blockMediumAndAbove)
        ]
        
        XCTAssertEqual(settings.count, 4)
        
        // Verify all categories are covered
        let categories = settings.map { $0.category }
        XCTAssertTrue(categories.contains(.harassment))
        XCTAssertTrue(categories.contains(.hateSpeech))
        XCTAssertTrue(categories.contains(.sexuallyExplicit))
        XCTAssertTrue(categories.contains(.dangerousContent))
    }
    
    func testSafetyRatings() {
        // Test SafetyRating struct
        let rating = SafetyRating(
            category: .harassment,
            probability: .low,
            blocked: false
        )
        
        XCTAssertEqual(rating.category, .harassment)
        XCTAssertEqual(rating.probability, .low)
        XCTAssertEqual(rating.blocked, false)
    }
    
    func testHarmProbabilities() {
        XCTAssertEqual(HarmProbability.negligible.rawValue, "NEGLIGIBLE")
        XCTAssertEqual(HarmProbability.low.rawValue, "LOW")
        XCTAssertEqual(HarmProbability.medium.rawValue, "MEDIUM")
        XCTAssertEqual(HarmProbability.high.rawValue, "HIGH")
    }
    
    func testPromptFeedback() {
        let safetyRatings = [
            SafetyRating(category: .harassment, probability: .low, blocked: false),
            SafetyRating(category: .hateSpeech, probability: .negligible, blocked: false)
        ]
        
        let feedback = PromptFeedback(
            blockReason: .safety,
            safetyRatings: safetyRatings
        )
        
        XCTAssertEqual(feedback.blockReason, .safety)
        XCTAssertEqual(feedback.safetyRatings?.count, 2)
        XCTAssertEqual(feedback.safetyRatings?.first?.category, .harassment)
        XCTAssertEqual(feedback.safetyRatings?.first?.probability, .low)
    }
    
    func testBlockReasons() {
        XCTAssertEqual(FinishReason.stop.rawValue, "STOP")
        XCTAssertEqual(FinishReason.maxTokens.rawValue, "MAX_TOKENS")
        XCTAssertEqual(FinishReason.safety.rawValue, "SAFETY")
        XCTAssertEqual(FinishReason.recitation.rawValue, "RECITATION")
    }
}