import XCTest
@testable import GeminiKit

final class FunctionBuilderTests: XCTestCase {
    
    func testBasicFunctionBuilder() {
        let function = FunctionBuilder(
            name: "get_weather",
            description: "Get weather information"
        )
        .build()
        
        XCTAssertEqual(function.name, "get_weather")
        XCTAssertEqual(function.description, "Get weather information")
        XCTAssertTrue(function.parameters.properties?.isEmpty ?? true)
        XCTAssertTrue(function.parameters.required?.isEmpty ?? true)
    }
    
    func testFunctionWithStringParameter() {
        let function = FunctionBuilder(
            name: "greet",
            description: "Greet a person"
        )
        .addString("name", description: "Person's name", required: true)
        .build()
        
        XCTAssertEqual(function.name, "greet")
        XCTAssertEqual(function.parameters.type, "object")
        
        if let properties = function.parameters.properties,
           let nameParam = properties["name"] {
            XCTAssertEqual(nameParam.type, "string")
            XCTAssertEqual(nameParam.description, "Person's name")
        } else {
            XCTFail("Expected name parameter")
        }
        
        XCTAssertEqual(function.parameters.required, ["name"])
    }
    
    func testFunctionWithEnumParameter() {
        let function = FunctionBuilder(
            name: "set_mode",
            description: "Set operation mode"
        )
        .addString(
            "mode",
            description: "Operation mode",
            enumValues: ["fast", "normal", "slow"],
            required: true
        )
        .build()
        
        if let properties = function.parameters.properties,
           let modeParam = properties["mode"] {
            XCTAssertEqual(modeParam.type, "string")
            XCTAssertEqual(modeParam.enum, ["fast", "normal", "slow"])
        } else {
            XCTFail("Expected mode parameter with enum")
        }
    }
    
    func testFunctionWithMultipleParameterTypes() {
        let function = FunctionBuilder(
            name: "process_data",
            description: "Process various data"
        )
        .addString("name", description: "Name", required: true)
        .addInteger("count", description: "Count", required: true)
        .addNumber("price", description: "Price", required: false)
        .addBoolean("active", description: "Is active", required: false)
        .build()
        
        guard let properties = function.parameters.properties else {
            XCTFail("Expected properties")
            return
        }
        
        XCTAssertEqual(properties["name"]?.type, "string")
        XCTAssertEqual(properties["count"]?.type, "integer")
        XCTAssertEqual(properties["price"]?.type, "number")
        XCTAssertEqual(properties["active"]?.type, "boolean")
        
        XCTAssertEqual(function.parameters.required?.sorted(), ["count", "name"])
    }
    
    func testFunctionWithArrayParameter() {
        let function = FunctionBuilder(
            name: "process_items",
            description: "Process multiple items"
        )
        .addArray(
            "items",
            itemType: "string",
            description: "List of items",
            required: true
        )
        .build()
        
        if let properties = function.parameters.properties,
           let itemsParam = properties["items"] {
            XCTAssertEqual(itemsParam.type, "array")
            if case .array(_, let items) = itemsParam,
               case .string = items {
                // Success - array of strings
            } else {
                XCTFail("Expected array of strings")
            }
        } else {
            XCTFail("Expected items array parameter")
        }
    }
    
    
    func testFunctionCodable() throws {
        let original = FunctionBuilder(
            name: "test_function",
            description: "Test function"
        )
        .addString("param1", description: "First parameter", required: true)
        .addInteger("param2", description: "Second parameter", required: false)
        .build()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FunctionDeclaration.self, from: data)
        
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.description, decoded.description)
        XCTAssertEqual(original.parameters.type, decoded.parameters.type)
        XCTAssertEqual(original.parameters.required, decoded.parameters.required)
    }
}