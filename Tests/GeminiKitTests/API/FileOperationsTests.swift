import XCTest
@testable import GeminiKit

final class FileOperationsTests: XCTestCase {
    
    func testFile() {
        let file = File(
            name: "files/abc123",
            displayName: "document.pdf",
            mimeType: "application/pdf",
            sizeBytes: "1048576",
            createTime: "2024-01-01T00:00:00Z",
            updateTime: "2024-01-01T00:00:00Z",
            expirationTime: "2024-01-02T00:00:00Z",
            sha256Hash: "abc123hash",
            uri: "https://generativelanguage.googleapis.com/v1/files/abc123",
            state: .active,
            error: nil,
            videoMetadata: nil
        )
        
        XCTAssertEqual(file.name, "files/abc123")
        XCTAssertEqual(file.displayName, "document.pdf")
        XCTAssertEqual(file.mimeType, "application/pdf")
        XCTAssertEqual(file.sizeBytes, "1048576")
        XCTAssertEqual(file.state, .active)
        XCTAssertNil(file.error)
    }
    
    func testFileState() {
        XCTAssertEqual(FileState.processing.rawValue, "PROCESSING")
        XCTAssertEqual(FileState.active.rawValue, "ACTIVE")
        XCTAssertEqual(FileState.failed.rawValue, "FAILED")
    }
    
    func testFileWithError() {
        let file = File(
            name: "files/error",
            displayName: "error.txt",
            mimeType: "text/plain",
            sizeBytes: nil,
            createTime: nil,
            updateTime: nil,
            expirationTime: nil,
            sha256Hash: nil,
            uri: nil,
            state: .failed,
            error: nil,
            videoMetadata: nil
        )
        
        XCTAssertEqual(file.state, .failed)
        XCTAssertNil(file.error)
    }
    
    func testFileMetadata() {
        let file = File(
            name: "",
            displayName: "test.txt",
            mimeType: "text/plain",
            sizeBytes: nil,
            createTime: nil,
            updateTime: nil,
            expirationTime: nil,
            sha256Hash: nil,
            uri: nil,
            state: nil,
            error: nil,
            videoMetadata: nil
        )
        
        XCTAssertEqual(file.displayName, "test.txt")
        XCTAssertEqual(file.mimeType, "text/plain")
    }
    
    func testListFilesResponse() {
        let file1 = File(
            name: "files/1",
            displayName: "file1.txt",
            mimeType: "text/plain",
            sizeBytes: "100",
            createTime: nil,
            updateTime: nil,
            expirationTime: nil,
            sha256Hash: nil,
            uri: nil,
            state: .active,
            error: nil,
            videoMetadata: nil
        )
        
        let file2 = File(
            name: "files/2",
            displayName: "file2.jpg",
            mimeType: "image/jpeg",
            sizeBytes: "5000",
            createTime: nil,
            updateTime: nil,
            expirationTime: nil,
            sha256Hash: nil,
            uri: nil,
            state: .active,
            error: nil,
            videoMetadata: nil
        )
        
        let response = ListFilesResponse(
            files: [file1, file2],
            nextPageToken: "token123"
        )
        
        XCTAssertEqual(response.files?.count, 2)
        XCTAssertEqual(response.files?.first?.name, "files/1")
        XCTAssertEqual(response.files?.last?.name, "files/2")
        XCTAssertEqual(response.nextPageToken, "token123")
    }
}