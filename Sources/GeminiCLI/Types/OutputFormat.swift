import Foundation

/// Supported output formats for CLI commands
enum OutputFormat: String, CaseIterable {
    case text
    case json
    case markdown
    
    var mimeType: String? {
        switch self {
        case .text:
            return nil
        case .json:
            return "application/json"
        case .markdown:
            return "text/markdown"
        }
    }
}