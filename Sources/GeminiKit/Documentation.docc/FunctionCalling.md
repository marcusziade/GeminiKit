# Function Calling

Enable Gemini models to interact with external tools and APIs through function calling.

## Overview

Function calling allows Gemini models to generate structured data that your application can use to call external APIs or perform actions. The model doesn't execute functions directly - it provides structured instructions for your code to execute.

## Basic Function Definition

Define functions using the `FunctionBuilder`:

```swift
// Weather function
let getWeather = FunctionBuilder(
    name: "get_weather",
    description: "Get current weather for a location"
)
.addString("location", description: "City and state/country", required: true)
.addString("unit", 
    description: "Temperature unit",
    enumValues: ["celsius", "fahrenheit"],
    required: false
)
.build()

// Calculator function
let calculate = FunctionBuilder(
    name: "calculate",
    description: "Perform mathematical calculations"
)
.addString("expression", description: "Mathematical expression to evaluate", required: true)
.build()
```

## Using Functions

### Manual Function Handling

```swift
// Define available functions
let functions = [getWeather, calculate]

// Generate with functions
let response = try await gemini.generateContent(
    model: .gemini25Flash,
    messages: [Content.user("What's the weather in Tokyo?")],
    tools: [Tool(functionDeclarations: functions)]
)

// Check for function calls
if let functionCall = response.candidates?.first?.content.parts.first?.functionCall {
    switch functionCall.name {
    case "get_weather":
        let location = functionCall.args["location"] as? String ?? ""
        let unit = functionCall.args["unit"] as? String ?? "celsius"
        
        // Call your weather API
        let weatherData = await fetchWeather(location: location, unit: unit)
        
        // Send function response back
        let functionResponse = Content.function(
            response: FunctionResponse(
                name: "get_weather",
                response: weatherData
            )
        )
        
        // Continue conversation with function result
        let finalResponse = try await gemini.generateContent(
            model: .gemini25Flash,
            messages: [
                Content.user("What's the weather in Tokyo?"),
                Content.model([Part.functionCall(functionCall)]),
                functionResponse
            ],
            tools: [Tool(functionDeclarations: functions)]
        )
        
    case "calculate":
        // Handle calculation
        break
        
    default:
        print("Unknown function: \(functionCall.name)")
    }
}
```

### Automatic Function Execution

Use the convenience method for automatic execution:

```swift
let response = try await gemini.executeWithFunctions(
    model: .gemini25Flash,
    messages: [Content.user("What's the weather in Tokyo and calculate 25*4")],
    functions: [getWeather, calculate],
    functionHandlers: [
        "get_weather": { call in
            let location = call.args["location"] as? String ?? ""
            // Fetch real weather data
            return [
                "temperature": 22,
                "condition": "sunny",
                "humidity": 65
            ]
        },
        "calculate": { call in
            let expression = call.args["expression"] as? String ?? ""
            // Evaluate expression safely
            return ["result": 100]
        }
    ]
)

print(response.candidates?.first?.content.parts.first?.text ?? "")
```

## Advanced Function Types

### Complex Parameter Types

```swift
let searchProducts = FunctionBuilder(
    name: "search_products",
    description: "Search for products in catalog"
)
.addObject("filters",
    description: "Search filters",
    properties: [
        "category": ParameterProperty(
            type: "string",
            description: "Product category",
            enum: ["electronics", "clothing", "books"]
        ),
        "priceRange": ParameterProperty(
            type: "object",
            description: "Price range",
            properties: [
                "min": ParameterProperty(type: "number", description: "Minimum price"),
                "max": ParameterProperty(type: "number", description: "Maximum price")
            ]
        ),
        "inStock": ParameterProperty(
            type: "boolean",
            description: "Only show in-stock items"
        )
    ],
    required: ["category"]
)
.addInteger("limit", description: "Maximum results", required: false)
.build()
```

### Array Parameters

```swift
let processImages = FunctionBuilder(
    name: "process_images",
    description: "Process multiple images"
)
.addArray("imageUrls",
    description: "URLs of images to process",
    items: ParameterProperty(type: "string", format: "uri"),
    required: true
)
.addArray("operations",
    description: "Operations to apply",
    items: ParameterProperty(
        type: "string",
        enum: ["resize", "rotate", "filter", "compress"]
    ),
    required: true
)
.build()
```

## Function Calling Modes

Control how the model uses functions:

```swift
// Force function use
let toolConfig = ToolConfig(
    functionCallingConfig: FunctionCallingConfig(
        mode: .any,  // Must call at least one function
        allowedFunctionNames: ["get_weather"]  // Optional: restrict to specific functions
    )
)

// Automatic mode (default)
let autoConfig = ToolConfig(
    functionCallingConfig: FunctionCallingConfig(
        mode: .auto  // Model decides when to call functions
    )
)

// No functions
let noneConfig = ToolConfig(
    functionCallingConfig: FunctionCallingConfig(
        mode: .none  // Disable function calling
    )
)

let response = try await gemini.generateContent(
    model: .gemini25Flash,
    messages: [Content.user("What's the weather?")],
    tools: [Tool(functionDeclarations: [getWeather])],
    toolConfig: toolConfig
)
```

## Parallel Function Calls

Handle multiple function calls in a single response:

```swift
let response = try await gemini.generateContent(
    model: .gemini25Flash,
    messages: [Content.user("What's the weather in Tokyo, London, and New York?")],
    tools: [Tool(functionDeclarations: [getWeather])]
)

// Process all function calls
var functionResponses: [Content] = []
for part in response.candidates?.first?.content.parts ?? [] {
    if case .functionCall(let call) = part {
        let result = await processFunction(call)
        functionResponses.append(Content.function(
            response: FunctionResponse(name: call.name, response: result)
        ))
    }
}

// Send all responses back
let finalResponse = try await gemini.generateContent(
    model: .gemini25Flash,
    messages: [
        Content.user("What's the weather in Tokyo, London, and New York?"),
        response.candidates!.first!.content,
        Content(role: .function, parts: functionResponses.flatMap { $0.parts })
    ]
)
```

## Best Practices

1. **Clear Descriptions**: Provide detailed function and parameter descriptions
2. **Type Safety**: Use appropriate parameter types and validation
3. **Error Handling**: Handle function execution errors gracefully
4. **Limit Functions**: Only include relevant functions for the task
5. **Response Validation**: Validate function arguments before execution

## Error Handling

```swift
do {
    let response = try await gemini.executeWithFunctions(
        model: .gemini25Flash,
        messages: messages,
        functions: functions,
        functionHandlers: handlers
    )
} catch GeminiError.functionExecutionFailed(let name, let error) {
    print("Function '\(name)' failed: \(error)")
} catch GeminiError.invalidFunctionResponse {
    print("Function returned invalid response")
}
```

## See Also

- <doc:CodeExecution> - Execute code directly in the model
- <doc:WebGrounding> - Access web search capabilities
- <doc:StructuredOutput> - Generate structured data without functions