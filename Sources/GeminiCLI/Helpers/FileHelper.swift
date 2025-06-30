import Foundation
import GeminiKit

/// Helper for file operations in CLI commands
struct FileHelper {
    
    /// Validate file exists and return URL
    static func validateFile(at path: String) throws -> URL {
        let url = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw GeminiError.fileError("File not found at path: \(path)")
        }
        
        return url
    }
    
    /// Save data to file
    static func saveData(_ data: Data, to path: String) throws {
        let url = URL(fileURLWithPath: path)
        
        do {
            try data.write(to: url)
        } catch {
            throw GeminiError.fileError("Failed to save file: \(error.localizedDescription)")
        }
    }
    
    /// Load file data with size validation
    static func loadFileData(from url: URL, maxSize: Int? = nil) throws -> Data {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int,
               let maxSize = maxSize,
               fileSize > maxSize {
                throw GeminiError.fileTooLarge(maxSize: maxSize, actualSize: fileSize)
            }
            
            return try Data(contentsOf: url)
        } catch let error as GeminiError {
            throw error
        } catch {
            throw GeminiError.fileError("Failed to load file: \(error.localizedDescription)")
        }
    }
    
    /// Parse time in MM:SS format
    static func parseTime(_ timeString: String) -> String {
        return timeString
    }
}