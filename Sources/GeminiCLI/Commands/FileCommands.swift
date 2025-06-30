import ArgumentParser
import Foundation
import GeminiKit

/// Command for uploading files
struct UploadCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload a file"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "Path to the file to upload")
    var filePath: String
    
    @Option(name: .shortAndLong, help: "Display name for the file")
    var name: String?
    
    func execute(with gemini: GeminiKit) async throws {
        let fileURL = try FileHelper.validateFile(at: filePath)
        
        let file = try await gemini.uploadFile(
            from: fileURL,
            displayName: name ?? fileURL.lastPathComponent
        )
        
        print("File uploaded successfully:")
        OutputFormatter.printFileInfo(file)
    }
}

/// Command for listing uploaded files
struct ListFilesCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "list-files",
        abstract: "List uploaded files"
    )
    
    @OptionGroup var options: CommonOptions
    
    func execute(with gemini: GeminiKit) async throws {
        let response = try await gemini.listFiles()
        
        guard let files = response.files, !files.isEmpty else {
            print("No files found")
            return
        }
        
        print("Files:")
        for file in files {
            print("- \(file.displayName ?? file.name) (\(file.mimeType), \(file.sizeBytes ?? "Unknown") bytes)")
            print("  URI: \(file.uri ?? "N/A")")
        }
    }
}

/// Command for deleting uploaded files
struct DeleteFileCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-file",
        abstract: "Delete an uploaded file"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "Resource name of the file to delete")
    var name: String
    
    func execute(with gemini: GeminiKit) async throws {
        try await gemini.deleteFile(name: name)
        print("File deleted successfully")
    }
}