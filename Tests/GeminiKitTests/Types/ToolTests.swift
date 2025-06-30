import XCTest
@testable import GeminiKit

final class ToolTests: XCTestCase {
    
    func testFunctionDeclarationTool() {
        let function = FunctionDeclaration(
            name: "calculate",
            description: "Perform calculations",
            parameters: FunctionParameters(
                properties: [
                    "operation": .string(description: "The operation to perform", enum: ["add", "subtract"]),
                    "a": .number(description: "First number"),
                    "b": .number(description: "Second number")
                ],
                required: ["operation", "a", "b"]
            )
        )
        
        let tool = Tool.functionDeclarations([function])
        
        if case .functionDeclarations(let functions) = tool {
            XCTAssertEqual(functions.count, 1)
            XCTAssertEqual(functions.first?.name, "calculate")
        } else {
            XCTFail("Expected functionDeclarations tool")
        }
    }
    
    func testCodeExecutionTool() {
        let tool = Tool.codeExecution
        
        if case .codeExecution = tool {
            // Success
        } else {
            XCTFail("Expected codeExecution tool")
        }
    }
    
    func testGoogleSearchTool() {
        let tool = Tool.googleSearch
        
        if case .googleSearch = tool {
            // Success
        } else {
            XCTFail("Expected googleSearch tool")
        }
    }
    
    func testExecutableCodeLanguage() {
        XCTAssertEqual(ExecutableCode.Language.python.rawValue, "PYTHON")
        // Only Python is supported currently
    }
    
    func testCodeExecutionResultOutcome() {
        // CodeExecutionResult uses String for outcome, not an enum
        let result = CodeExecutionResult(outcome: "OK", output: "test")
        XCTAssertEqual(result.outcome, "OK")
        XCTAssertEqual(result.output, "test")
    }
}