import Foundation
import GeminiKit

/// Handles formatting and display of command outputs
struct OutputFormatter {
    
    /// Print content from a generation response
    static func printContent(_ response: GenerateContentResponse) {
        if let text = response.candidates?.first?.content.parts.first {
            if case .text(let content) = text {
                print(content)
            }
        }
    }
    
    /// Print usage metadata if available
    static func printUsageMetadata(_ usage: UsageMetadata?) {
        guard let usage = usage else { return }
        
        print("\n---")
        print("Tokens - Prompt: \(usage.promptTokenCount), Output: \(usage.candidatesTokenCount ?? 0), Total: \(usage.totalTokenCount)")
    }
    
    /// Print grounding metadata if available
    static func printGroundingMetadata(_ grounding: GroundingMetadata?) {
        guard let grounding = grounding else { return }
        
        print("\n---")
        if let queries = grounding.webSearchQueries, !queries.isEmpty {
            print("Web searches:")
            queries.forEach { query in
                print("- \(query)")
            }
        }
        
        if let chunks = grounding.groundingChunks, !chunks.isEmpty {
            print("\nSources:")
            for chunk in chunks {
                if let web = chunk.web {
                    print("- \(web.title ?? "Untitled"): \(web.uri ?? "No URL")")
                }
            }
        }
    }
    
    /// Print file information
    static func printFileInfo(_ file: File) {
        print("Name: \(file.name)")
        print("Display Name: \(file.displayName ?? "N/A")")
        print("MIME Type: \(file.mimeType)")
        print("Size: \(file.sizeBytes ?? "Unknown")")
        print("URI: \(file.uri ?? "N/A")")
    }
    
    /// Print code execution results
    static func printCodeExecutionParts(_ parts: [Part]) {
        for part in parts {
            switch part {
            case .text(let text):
                print(text)
            case .executableCode(let code):
                print("\n[CODE TO EXECUTE]")
                print("Language: \(code.language.rawValue)")
                print(code.code)
            case .codeExecutionResult(let result):
                print("\n[EXECUTION RESULT]")
                print("Outcome: \(result.outcome)")
                print("Output: \(result.output)")
            default:
                break
            }
        }
    }
}