import XCTest
@testable import GeminiKit

final class VideoTests: XCTestCase {
    var gemini: GeminiKit!
    
    override func setUp() {
        super.setUp()
        gemini = GeminiKit(apiKey: "test-key")
    }
    
    // MARK: - Video Generation Tests
    
    func testVideoGenerationRequest() async throws {
        let parameters = VeoParameters(
            aspectRatio: "16:9",
            personGeneration: "dont_allow",
            numberOfVideos: 1,
            durationSeconds: 5
        )
        
        let request = VeoPredictRequest(
            prompt: "A beautiful sunset over the ocean",
            parameters: parameters
        )
        
        XCTAssertEqual(request.instances.count, 1)
        XCTAssertEqual(request.instances[0].prompt, "A beautiful sunset over the ocean")
        XCTAssertNil(request.instances[0].image)
        XCTAssertEqual(request.parameters.aspectRatio, "16:9")
        XCTAssertEqual(request.parameters.durationSeconds, 5)
    }
    
    func testVideoGenerationWithImage() async throws {
        let imageData = "base64EncodedImageData"
        let parameters = VeoParameters(
            aspectRatio: "9:16",
            numberOfVideos: 2,
            durationSeconds: 8
        )
        
        let request = VeoPredictRequest(
            prompt: "Make this image move",
            image: imageData,
            parameters: parameters
        )
        
        XCTAssertEqual(request.instances[0].image, imageData)
        XCTAssertEqual(request.parameters.aspectRatio, "9:16")
        XCTAssertEqual(request.parameters.numberOfVideos, 2)
        XCTAssertEqual(request.parameters.durationSeconds, 8)
    }
    
    func testVideoAspectRatios() {
        XCTAssertEqual(VideoAspectRatio.landscape.rawValue, "16:9")
        XCTAssertEqual(VideoAspectRatio.portrait.rawValue, "9:16")
        
        let allRatios = VideoAspectRatio.allCases
        XCTAssertEqual(allRatios.count, 2)
    }
    
    func testPersonGenerationOptions() {
        XCTAssertEqual(PersonGeneration.dontAllow.rawValue, "dont_allow")
        XCTAssertEqual(PersonGeneration.allowAdult.rawValue, "allow_adult")
        XCTAssertEqual(PersonGeneration.allowAll.rawValue, "allow_all")
    }
    
    // MARK: - Video Understanding Tests
    
    func testVideoMetadata() {
        let metadata = VideoMetadata(
            startOffset: "00:30",
            endOffset: "01:45",
            fps: 5.0
        )
        
        XCTAssertEqual(metadata.startOffset, "00:30")
        XCTAssertEqual(metadata.endOffset, "01:45")
        XCTAssertEqual(metadata.fps, 5.0)
    }
    
    func testVideoMetadataPartEncoding() throws {
        let metadata = VideoMetadata(startOffset: "00:10", fps: 2.0)
        let part = Part.videoMetadata(metadata)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(part)
        
        let decoder = JSONDecoder()
        let decodedPart = try decoder.decode(Part.self, from: data)
        
        if case .videoMetadata(let decodedMetadata) = decodedPart {
            XCTAssertEqual(decodedMetadata.startOffset, "00:10")
            XCTAssertNil(decodedMetadata.endOffset)
            XCTAssertEqual(decodedMetadata.fps, 2.0)
        } else {
            XCTFail("Expected videoMetadata part")
        }
    }
    
    func testFileDataWithVideo() {
        let fileData = FileData(
            mimeType: "video/mp4",
            fileUri: "https://example.com/video.mp4"
        )
        
        XCTAssertEqual(fileData.mimeType, "video/mp4")
        XCTAssertEqual(fileData.fileUri, "https://example.com/video.mp4")
    }
    
    func testYouTubeURLFileData() {
        let youtubeURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let fileData = FileData(
            mimeType: "video/*",
            fileUri: youtubeURL
        )
        
        XCTAssertEqual(fileData.fileUri, youtubeURL)
        XCTAssertEqual(fileData.mimeType, "video/*")
    }
    
    // MARK: - Content Creation Tests
    
    func testContentWithVideo() {
        let videoData = FileData(mimeType: "video/mp4", fileUri: "file://video.mp4")
        let metadata = VideoMetadata(fps: 5.0)
        
        let content = Content(
            role: .user,
            parts: [
                .fileData(videoData),
                .videoMetadata(metadata),
                .text("What's happening in this video?")
            ]
        )
        
        XCTAssertEqual(content.role, .user)
        XCTAssertEqual(content.parts.count, 3)
    }
    
    func testContentWithMultipleVideoParts() {
        let parts: [Part] = [
            .text("Analyze these video segments:"),
            .fileData(FileData(mimeType: "video/mp4", fileUri: "video1.mp4")),
            .videoMetadata(VideoMetadata(startOffset: "00:00", endOffset: "00:30")),
            .text("at 00:05 and"),
            .fileData(FileData(mimeType: "video/mp4", fileUri: "video2.mp4")),
            .videoMetadata(VideoMetadata(startOffset: "00:10", endOffset: "00:20")),
            .text("at 00:15")
        ]
        
        let content = Content(role: .user, parts: parts)
        XCTAssertEqual(content.parts.count, 7)
    }
    
    // MARK: - Operation Tests
    
    func testOperationResponse() throws {
        let videoData = VideoData(
            uri: "https://example.com/generated-video.mp4",
            bytesBase64Encoded: nil
        )
        
        let prediction = VeoPrediction(video: videoData)
        let response = OperationResponse(predictions: [prediction])
        let operation = Operation(
            name: "operations/abc123",
            done: true,
            error: nil,
            response: response,
            metadata: nil
        )
        
        XCTAssertTrue(operation.done ?? false)
        XCTAssertNil(operation.error)
        XCTAssertEqual(operation.response?.predictions?.count, 1)
        XCTAssertEqual(operation.response?.predictions?[0].video?.uri, "https://example.com/generated-video.mp4")
    }
    
    func testOperationError() {
        let error = Status(code: 500, message: "Video generation failed", details: nil)
        let operation = Operation(
            name: "operations/xyz789",
            done: true,
            error: error,
            response: nil,
            metadata: nil
        )
        
        XCTAssertTrue(operation.done ?? false)
        XCTAssertNotNil(operation.error)
        XCTAssertEqual(operation.error?.code, 500)
        XCTAssertEqual(operation.error?.message, "Video generation failed")
    }
    
    // MARK: - MIME Type Tests
    
    func testVideoMimeTypes() {
        let supportedTypes = [
            "video/mp4",
            "video/mpeg",
            "video/mov",
            "video/avi",
            "video/x-flv",
            "video/mpg",
            "video/webm",
            "video/wmv",
            "video/3gpp"
        ]
        
        for mimeType in supportedTypes {
            let fileData = FileData(mimeType: mimeType, fileUri: "test.video")
            XCTAssertEqual(fileData.mimeType, mimeType)
        }
    }
}