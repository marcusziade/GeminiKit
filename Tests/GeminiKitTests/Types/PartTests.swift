import XCTest
@testable import GeminiKit

final class PartTests: XCTestCase {
    
    func testTextPart() {
        let part = Part.text("Hello, world!")
        
        if case .text(let content) = part {
            XCTAssertEqual(content, "Hello, world!")
        } else {
            XCTFail("Expected text part")
        }
    }
    
    func testInlineDataPart() {
        let data = InlineData(mimeType: "image/png", data: "base64data")
        let part = Part.inlineData(data)
        
        if case .inlineData(let inlineData) = part {
            XCTAssertEqual(inlineData.mimeType, "image/png")
            XCTAssertEqual(inlineData.data, "base64data")
        } else {
            XCTFail("Expected inlineData part")
        }
    }
    
    func testFileDataPart() {
        let fileData = FileData(mimeType: "video/mp4", fileUri: "https://example.com/video.mp4")
        let part = Part.fileData(fileData)
        
        if case .fileData(let data) = part {
            XCTAssertEqual(data.mimeType, "video/mp4")
            XCTAssertEqual(data.fileUri, "https://example.com/video.mp4")
        } else {
            XCTFail("Expected fileData part")
        }
    }
    
    func testFunctionCallPart() {
        let functionCall = FunctionCall(name: "calculate", args: ["a": AnyCodable(5), "b": AnyCodable(3)])
        let part = Part.functionCall(functionCall)
        
        if case .functionCall(let call) = part {
            XCTAssertEqual(call.name, "calculate")
            XCTAssertNotNil(call.args)
        } else {
            XCTFail("Expected functionCall part")
        }
    }
    
    func testFunctionResponsePart() {
        let response = FunctionResponse(name: "calculate", response: ["result": AnyCodable(8)])
        let part = Part.functionResponse(response)
        
        if case .functionResponse(let resp) = part {
            XCTAssertEqual(resp.name, "calculate")
            XCTAssertNotNil(resp.response)
        } else {
            XCTFail("Expected functionResponse part")
        }
    }
    
    func testExecutableCodePart() {
        let code = ExecutableCode(language: .python, code: "print('Hello')")
        let part = Part.executableCode(code)
        
        if case .executableCode(let execCode) = part {
            XCTAssertEqual(execCode.language, .python)
            XCTAssertEqual(execCode.code, "print('Hello')")
        } else {
            XCTFail("Expected executableCode part")
        }
    }
    
    func testCodeExecutionResultPart() {
        let result = CodeExecutionResult(outcome: "OK", output: "Hello")
        let part = Part.codeExecutionResult(result)
        
        if case .codeExecutionResult(let execResult) = part {
            XCTAssertEqual(execResult.outcome, "OK")
            XCTAssertEqual(execResult.output, "Hello")
        } else {
            XCTFail("Expected codeExecutionResult part")
        }
    }
    
    func testVideoMetadataPart() {
        let metadata = VideoMetadata(startOffset: "00:10", endOffset: "00:30", fps: 24)
        let part = Part.videoMetadata(metadata)
        
        if case .videoMetadata(let meta) = part {
            XCTAssertEqual(meta.startOffset, "00:10")
            XCTAssertEqual(meta.endOffset, "00:30")
            XCTAssertEqual(meta.fps, 24)
        } else {
            XCTFail("Expected videoMetadata part")
        }
    }
    
    // Note: thought part is not available in the current Part enum
}