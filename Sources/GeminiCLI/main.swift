import ArgumentParser
import Foundation
import GeminiKit

@main
struct GeminiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gemini-cli",
        abstract: "A command-line interface for testing GeminiKit SDK",
        version: "1.0.0",
        subcommands: [
            Generate.self,
            Stream.self,
            Count.self,
            Chat.self,
            Upload.self,
            ListFiles.self,
            DeleteFile.self,
            GenerateImage.self,
            GenerateVideo.self,
            GenerateSpeech.self,
            Embeddings.self,
            FunctionCall.self,
            CodeExecution.self,
            WebGrounding.self,
            OpenAIChat.self,
            ConfigInfo.self
        ]
    )
}

// MARK: - Common Options

struct CommonOptions: ParsableArguments {
    @Option(name: .shortAndLong, help: "API key (defaults to GEMINI_API_KEY env var)")
    var apiKey: String?
    
    @Option(help: "Model to use")
    var model: String = "gemini-2.5-flash"
    
    func createGeminiKit() throws -> GeminiKit {
        guard let key = apiKey ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
            throw ValidationError("API key required. Set GEMINI_API_KEY or use --api-key")
        }
        return GeminiKit(apiKey: key)
    }
    
    func getModel() throws -> GeminiModel {
        guard let geminiModel = GeminiModel(rawValue: model) else {
            throw ValidationError("Invalid model: \(model)")
        }
        return geminiModel
    }
}

// MARK: - Generate Command

struct Generate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate content from a prompt"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The prompt to generate content from")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "System instruction")
    var system: String?
    
    @Option(name: .shortAndLong, help: "Temperature (0.0-2.0)")
    var temperature: Double?
    
    @Option(name: .shortAndLong, help: "Max output tokens")
    var maxTokens: Int?
    
    @Option(help: "Output format (text/json)")
    var format: String = "text"
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let model = try common.getModel()
        
        var config = GenerationConfig(
            temperature: temperature,
            maxOutputTokens: maxTokens
        )
        
        if format == "json" {
            config = GenerationConfig(
                temperature: config.temperature,
                maxOutputTokens: config.maxOutputTokens,
                responseMimeType: "application/json"
            )
        }
        
        let response = try await gemini.generateContent(
            model: model,
            prompt: prompt,
            systemInstruction: system,
            config: config
        )
        
        if let text = response.candidates?.first?.content.parts.first {
            if case .text(let content) = text {
                print(content)
            }
        }
        
        if let usage = response.usageMetadata {
            print("\n---")
            print("Tokens - Prompt: \(usage.promptTokenCount), Output: \(usage.candidatesTokenCount ?? 0), Total: \(usage.totalTokenCount)")
        }
    }
}

// MARK: - Stream Command

struct Stream: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Stream content generation"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The prompt to generate content from")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "System instruction")
    var system: String?
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let model = try common.getModel()
        
        let stream = try await gemini.streamGenerateContent(
            model: model,
            prompt: prompt,
            systemInstruction: system
        )
        
        var receivedContent = false
        for try await response in stream {
            if let text = response.candidates?.first?.content.parts.first {
                if case .text(let content) = text {
                    print(content, terminator: "")
                    fflush(stdout)
                    receivedContent = true
                }
            }
        }
        if receivedContent {
            print()
        }
    }
}

// MARK: - Count Command

struct Count: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Count tokens in text"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The text to count tokens for")
    var text: String
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let model = try common.getModel()
        
        let response = try await gemini.countTokens(
            model: model,
            prompt: text
        )
        
        print("Total tokens: \(response.totalTokens)")
    }
}

// MARK: - Chat Command

struct Chat: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Interactive chat session"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Option(name: .shortAndLong, help: "System instruction")
    var system: String?
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let model = try common.getModel()
        
        let chat = gemini.startChat(
            model: model,
            systemInstruction: system
        )
        
        print("Chat session started. Type 'exit' to quit.")
        print("---")
        
        while true {
            print("\nYou: ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }
            
            if input.lowercased() == "exit" {
                print("Goodbye!")
                break
            }
            
            print("\nAssistant: ", terminator: "")
            
            let stream = try await chat.streamMessage(input)
            for try await chunk in stream {
                print(chunk, terminator: "")
                fflush(stdout)
            }
            print("\n---")
        }
    }
}

// MARK: - File Commands

struct Upload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Upload a file"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "Path to the file to upload")
    var filePath: String
    
    @Option(name: .shortAndLong, help: "Display name for the file")
    var name: String?
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let fileURL = URL(fileURLWithPath: filePath)
        
        let file = try await gemini.uploadFile(
            from: fileURL,
            displayName: name ?? fileURL.lastPathComponent
        )
        
        print("File uploaded successfully:")
        print("Name: \(file.name)")
        print("Display Name: \(file.displayName ?? "N/A")")
        print("MIME Type: \(file.mimeType)")
        print("Size: \(file.sizeBytes ?? "Unknown")")
        print("URI: \(file.uri ?? "N/A")")
    }
}

struct ListFiles: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List uploaded files"
    )
    
    @OptionGroup var common: CommonOptions
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
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

struct DeleteFile: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Delete an uploaded file"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "Resource name of the file to delete")
    var name: String
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        try await gemini.deleteFile(name: name)
        print("File deleted successfully")
    }
}

// MARK: - Image Generation

struct GenerateImage: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate images from text"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The prompt for image generation")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "Number of images (1-4)")
    var count: Int = 1
    
    @Option(name: .shortAndLong, help: "Aspect ratio (1:1, 3:4, 4:3, 9:16, 16:9)")
    var ratio: String = "1:1"
    
    @Option(name: .shortAndLong, help: "Output directory")
    var output: String = "."
    
    @Option(help: "Negative prompt")
    var negative: String?
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        
        let aspectRatio = ImageAspectRatio(rawValue: ratio) ?? .square
        let outputDir = URL(fileURLWithPath: output)
        
        print("Generating \(count) image(s)...")
        
        let urls = try await gemini.generateImageFiles(
            model: .imagen30Generate002,
            prompt: prompt,
            outputDirectory: outputDir,
            count: count,
            aspectRatio: aspectRatio,
            negativePrompt: negative
        )
        
        print("Images saved:")
        for url in urls {
            print("- \(url.path)")
        }
    }
}

// MARK: - Video Generation

struct GenerateVideo: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate videos from text"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The prompt for video generation")
    var prompt: String
    
    @Option(name: .shortAndLong, help: "Duration in seconds (5 or 8)")
    var duration: Int = 5
    
    @Option(name: .shortAndLong, help: "Aspect ratio (16:9 or 9:16)")
    var ratio: String = "16:9"
    
    @Option(help: "Image file for image-to-video")
    var image: String?
    
    @Flag(help: "Wait for completion")
    var wait = false
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        
        var imageData: String?
        if let imagePath = image {
            let data = try Data(contentsOf: URL(fileURLWithPath: imagePath))
            imageData = data.base64EncodedString()
        }
        
        let aspectRatio = VideoAspectRatio(rawValue: ratio) ?? .landscape
        
        print("Starting video generation...")
        
        let operation = try await gemini.generateVideos(
            prompt: prompt,
            imageData: imageData,
            aspectRatio: aspectRatio,
            duration: duration
        )
        
        print("Operation started: \(operation)")
        
        if wait {
            print("Waiting for completion...")
            let videos = try await gemini.waitForVideos(operation)
            
            print("Videos generated:")
            for (index, video) in videos.enumerated() {
                if let uri = video.video?.uri {
                    print("- Video \(index + 1): \(uri)")
                }
            }
        }
    }
}

// MARK: - Speech Generation

struct GenerateSpeech: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate speech from text"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The text to convert to speech")
    var text: String
    
    @Option(name: .shortAndLong, help: "Voice name")
    var voice: String = "Zephyr"
    
    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "speech.wav"
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        
        guard let ttsVoice = TTSVoice(rawValue: voice) else {
            throw ValidationError("Invalid voice: \(voice)")
        }
        
        print("Generating speech...")
        
        let audioData = try await gemini.generateSpeech(
            text: text,
            voice: ttsVoice
        )
        
        let outputURL = URL(fileURLWithPath: output)
        try gemini.saveAudioToFile(audioData, outputURL: outputURL)
        
        print("Audio saved to: \(outputURL.path)")
    }
}

// MARK: - Embeddings

struct Embeddings: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate text embeddings"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The text to embed")
    var text: String
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        
        let response = try await gemini.createEmbeddings(
            EmbeddingsRequest(input: text)
        )
        
        if let embedding = response.data.first {
            print("Embedding dimensions: \(embedding.embedding.count)")
            print("First 10 values: \(embedding.embedding.prefix(10).map { String(format: "%.4f", $0) }.joined(separator: ", "))")
        }
    }
}

// MARK: - Function Calling

struct FunctionCall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Test function calling"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The prompt that may trigger function calls")
    var prompt: String
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let model = try common.getModel()
        
        // Define calculator function
        let calculator = FunctionBuilder(
            name: "calculate",
            description: "Perform basic arithmetic operations"
        )
        .addString("operation", description: "The operation to perform", enumValues: ["add", "subtract", "multiply", "divide"], required: true)
        .addNumber("a", description: "First number", required: true)
        .addNumber("b", description: "Second number", required: true)
        .build()
        
        // Define weather function
        let weather = FunctionBuilder(
            name: "get_weather",
            description: "Get weather information for a location"
        )
        .addString("location", description: "The location to get weather for", required: true)
        .addString("unit", description: "Temperature unit", enumValues: ["celsius", "fahrenheit"])
        .build()
        
        let handlers = [
            FunctionHandlers.calculator(),
            FunctionHandlers.weather()
        ]
        
        let functionHandlers = Dictionary(uniqueKeysWithValues: handlers)
        
        print("Executing with functions...")
        
        let response = try await gemini.executeWithFunctions(
            model: model,
            messages: [Content.user(prompt)],
            functions: [calculator, weather],
            functionHandlers: functionHandlers
        )
        
        if let text = response.candidates?.first?.content.parts.first {
            if case .text(let content) = text {
                print(content)
            }
        }
    }
}

// MARK: - Code Execution

struct CodeExecution: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Test code execution"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The prompt that may trigger code execution")
    var prompt: String
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let model = try common.getModel()
        
        let response = try await gemini.generateContent(
            model: model,
            messages: [Content.user(prompt)],
            tools: [.codeExecution]
        )
        
        if let candidate = response.candidates?.first {
            for part in candidate.content.parts {
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
}

// MARK: - Web Grounding

struct WebGrounding: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Test Google Search grounding"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The prompt that requires web information")
    var prompt: String
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        let model = try common.getModel()
        
        let response = try await gemini.generateContent(
            model: model,
            messages: [Content.user(prompt)],
            tools: [.googleSearch]
        )
        
        if let text = response.candidates?.first?.content.parts.first {
            if case .text(let content) = text {
                print(content)
            }
        }
        
        if let grounding = response.candidates?.first?.groundingMetadata {
            print("\n---")
            print("Web searches:")
            grounding.webSearchQueries?.forEach { query in
                print("- \(query)")
            }
            
            if let chunks = grounding.groundingChunks {
                print("\nSources:")
                for chunk in chunks {
                    if let web = chunk.web {
                        print("- \(web.title ?? "Untitled"): \(web.uri ?? "No URL")")
                    }
                }
            }
        }
    }
}

// MARK: - OpenAI Compatibility

struct OpenAIChat: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Test OpenAI-compatible chat completion"
    )
    
    @OptionGroup var common: CommonOptions
    
    @Argument(help: "The user message")
    var message: String
    
    @Option(name: .shortAndLong, help: "System message")
    var system: String?
    
    @Flag(help: "Stream the response")
    var stream = false
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        
        var messages: [ChatMessage] = []
        
        if let system = system {
            messages.append(ChatMessage(role: "system", content: system))
        }
        
        messages.append(ChatMessage(role: "user", content: message))
        
        let request = ChatCompletionRequest(
            model: common.model,
            messages: messages,
            stream: stream
        )
        
        if stream {
            let stream = try await gemini.streamChatCompletion(request)
            
            for try await chunk in stream {
                if let delta = chunk.choices.first?.delta.content {
                    print(delta, terminator: "")
                    fflush(stdout)
                }
            }
            print()
        } else {
            let response = try await gemini.createChatCompletion(request)
            
            if let content = response.choices.first?.message.content {
                if case .text(let text) = content {
                    print(text)
                }
            }
            
            if let usage = response.usage {
                print("\n---")
                print("Tokens - Prompt: \(usage.promptTokens), Completion: \(usage.completionTokens), Total: \(usage.totalTokens)")
            }
        }
    }
}

// MARK: - Config Info

struct ConfigInfo: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show configuration and available models"
    )
    
    @OptionGroup var common: CommonOptions
    
    mutating func run() async throws {
        let gemini = try common.createGeminiKit()
        
        print("Available Models:")
        print("\nText Generation:")
        for model in GeminiModel.allCases {
            if let window = model.contextWindow {
                print("- \(model.rawValue) (context: \(window) tokens)")
            }
        }
        
        print("\nSpecial Capabilities:")
        print("- Thinking: \(GeminiModel.allCases.filter { $0.supportsThinking }.map { $0.rawValue }.joined(separator: ", "))")
        print("- Image Generation: \(GeminiModel.allCases.filter { $0.supportsImageGeneration }.map { $0.rawValue }.joined(separator: ", "))")
        print("- Video Generation: \(GeminiModel.allCases.filter { $0.supportsVideoGeneration }.map { $0.rawValue }.joined(separator: ", "))")
        print("- TTS: \(GeminiModel.allCases.filter { $0.supportsTTS }.map { $0.rawValue }.joined(separator: ", "))")
        
        print("\nVoices:")
        for voice in TTSVoice.allCases.prefix(10) {
            print("- \(voice.rawValue)")
        }
        print("... and \(TTSVoice.allCases.count - 10) more")
    }
}