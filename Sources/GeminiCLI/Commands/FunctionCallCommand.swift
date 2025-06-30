import ArgumentParser
import Foundation
import GeminiKit

/// Command for testing function calling
struct FunctionCallCommand: CLICommand {
    static let configuration = CommandConfiguration(
        commandName: "function-call",
        abstract: "Test function calling"
    )
    
    @OptionGroup var options: CommonOptions
    
    @Argument(help: "The prompt that may trigger function calls")
    var prompt: String
    
    func execute(with gemini: GeminiKit) async throws {
        let model = try options.getModel()
        
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
        
        OutputFormatter.printContent(response)
    }
}