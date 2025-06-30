import XCTest
@testable import GeminiKit

final class GenerationConfigTests: XCTestCase {
    
    func testDefaultGenerationConfig() {
        let config = GenerationConfig()
        
        // All properties should be nil by default
        XCTAssertNil(config.temperature)
        XCTAssertNil(config.topP)
        XCTAssertNil(config.topK)
        XCTAssertNil(config.candidateCount)
        XCTAssertNil(config.maxOutputTokens)
        XCTAssertNil(config.stopSequences)
        XCTAssertNil(config.responseMimeType)
        XCTAssertNil(config.responseSchema)
        XCTAssertNil(config.responseModalities)
        XCTAssertNil(config.thinkingConfig)
        XCTAssertNil(config.speechConfig)
    }
    
    func testGenerationConfigWithAllValues() {
        let schema = ResponseSchema.object(
            properties: [
                "name": .string(enum: nil),
                "age": .integer
            ],
            required: ["name"],
            propertyOrdering: nil
        )
        
        let config = GenerationConfig(
            temperature: 0.8,
            topP: 0.95,
            topK: 40,
            candidateCount: 1,
            maxOutputTokens: 1024,
            stopSequences: ["END", "STOP"],
            responseModalities: [.text],
            responseMimeType: "application/json",
            responseSchema: schema,
            thinkingConfig: ThinkingConfig(thinkingBudget: 2048),
            speechConfig: nil
        )
        
        XCTAssertEqual(config.temperature, 0.8)
        XCTAssertEqual(config.topP, 0.95)
        XCTAssertEqual(config.topK, 40)
        XCTAssertEqual(config.candidateCount, 1)
        XCTAssertEqual(config.maxOutputTokens, 1024)
        XCTAssertEqual(config.stopSequences, ["END", "STOP"])
        XCTAssertEqual(config.responseMimeType, "application/json")
        XCTAssertNotNil(config.responseSchema)
        XCTAssertEqual(config.responseModalities, [.text])
        XCTAssertEqual(config.thinkingConfig?.thinkingBudget, 2048)
        XCTAssertNil(config.speechConfig)
    }
    
    func testResponseSchemaCodable() throws {
        let schema = ResponseSchema.object(
            properties: [
                "items": .array(
                    items: .object(
                        properties: [
                            "id": .integer,
                            "name": .string(enum: nil),
                            "active": .boolean
                        ],
                        required: ["id", "name"],
                        propertyOrdering: nil
                    )
                ),
                "total": .number
            ],
            required: ["items"],
            propertyOrdering: ["items", "total"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ResponseSchema.self, from: data)
        
        // Verify the decoded schema matches
        if case .object(let props, let req, let order) = decoded {
            XCTAssertEqual(req, ["items"])
            XCTAssertEqual(order, ["items", "total"])
            XCTAssertNotNil(props["items"])
            XCTAssertNotNil(props["total"])
        } else {
            XCTFail("Expected object schema")
        }
    }
    
    func testGenerationConfigCodable() throws {
        let original = GenerationConfig(
            temperature: 0.7,
            topP: 0.9,
            maxOutputTokens: 512,
            stopSequences: ["\\n\\n"],
            responseMimeType: "text/plain"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GenerationConfig.self, from: data)
        
        XCTAssertEqual(original.temperature, decoded.temperature)
        XCTAssertEqual(original.topP, decoded.topP)
        XCTAssertEqual(original.maxOutputTokens, decoded.maxOutputTokens)
        XCTAssertEqual(original.stopSequences, decoded.stopSequences)
        XCTAssertEqual(original.responseMimeType, decoded.responseMimeType)
    }
    
    func testResponseSchemaTypes() {
        // Test all schema types
        let stringSchema = ResponseSchema.string(enum: ["option1", "option2"])
        let numberSchema = ResponseSchema.number
        let integerSchema = ResponseSchema.integer
        let booleanSchema = ResponseSchema.boolean
        let arraySchema = ResponseSchema.array(items: .string(enum: nil))
        let objectSchema = ResponseSchema.object(
            properties: ["key": .string(enum: nil)],
            required: ["key"],
            propertyOrdering: nil
        )
        
        // Verify each type
        if case .string(let enumValues) = stringSchema {
            XCTAssertEqual(enumValues, ["option1", "option2"])
        } else {
            XCTFail("Expected string schema")
        }
        
        if case .number = numberSchema {
            // Success
        } else {
            XCTFail("Expected number schema")
        }
        
        if case .integer = integerSchema {
            // Success
        } else {
            XCTFail("Expected integer schema")
        }
        
        if case .boolean = booleanSchema {
            // Success
        } else {
            XCTFail("Expected boolean schema")
        }
        
        if case .array(let items) = arraySchema,
           case .string = items {
            // Success
        } else {
            XCTFail("Expected array schema with string items")
        }
        
        if case .object(let props, let req, _) = objectSchema {
            XCTAssertNotNil(props["key"])
            XCTAssertEqual(req, ["key"])
        } else {
            XCTFail("Expected object schema")
        }
    }
}