import Foundation

/// Request to generate content
public struct GenerateContentRequest: Codable, Equatable, Sendable {
    /// The content of the conversation
    public let contents: [Content]
    
    /// System-level instructions
    public let systemInstruction: Content?
    
    /// Generation configuration
    public let generationConfig: GenerationConfig?
    
    /// Tools available to the model
    public let tools: [Tool]?
    
    /// Tool configuration
    public let toolConfig: ToolConfig?
    
    /// Safety settings
    public let safetySettings: [SafetySetting]?
    
    /// Creates a new generate content request
    public init(
        contents: [Content],
        systemInstruction: Content? = nil,
        generationConfig: GenerationConfig? = nil,
        tools: [Tool]? = nil,
        toolConfig: ToolConfig? = nil,
        safetySettings: [SafetySetting]? = nil
    ) {
        self.contents = contents
        self.systemInstruction = systemInstruction
        self.generationConfig = generationConfig
        self.tools = tools
        self.toolConfig = toolConfig
        self.safetySettings = safetySettings
    }
}

/// Request to count tokens
public struct CountTokensRequest: Codable, Equatable, Sendable {
    /// The content to count tokens for
    public let contents: [Content]
    
    /// System-level instructions
    public let systemInstruction: Content?
    
    /// Tools available to the model
    public let tools: [Tool]?
    
    /// Creates a new count tokens request
    public init(
        contents: [Content],
        systemInstruction: Content? = nil,
        tools: [Tool]? = nil
    ) {
        self.contents = contents
        self.systemInstruction = systemInstruction
        self.tools = tools
    }
}

/// Tool available to the model
public enum Tool: Codable, Equatable, Sendable {
    case functionDeclarations([FunctionDeclaration])
    case codeExecution
    case googleSearch
    case urlContext(URLContext)
    
    enum CodingKeys: String, CodingKey {
        case functionDeclarations
        case codeExecution
        case googleSearch
        case urlContext
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let functions = try container.decodeIfPresent([FunctionDeclaration].self, forKey: .functionDeclarations) {
            self = .functionDeclarations(functions)
        } else if let _ = try container.decodeIfPresent(EmptyObject.self, forKey: .codeExecution) {
            self = .codeExecution
        } else if let _ = try container.decodeIfPresent(EmptyObject.self, forKey: .googleSearch) {
            self = .googleSearch
        } else if let urlContext = try container.decodeIfPresent(URLContext.self, forKey: .urlContext) {
            self = .urlContext(urlContext)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown tool type")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .functionDeclarations(let functions):
            try container.encode(functions, forKey: .functionDeclarations)
        case .codeExecution:
            try container.encode(EmptyObject(), forKey: .codeExecution)
        case .googleSearch:
            try container.encode(EmptyObject(), forKey: .googleSearch)
        case .urlContext(let context):
            try container.encode(context, forKey: .urlContext)
        }
    }
}

/// Function declaration
public struct FunctionDeclaration: Codable, Equatable, Sendable {
    /// The name of the function
    public let name: String
    
    /// Description of what the function does
    public let description: String
    
    /// The parameters the function accepts
    public let parameters: FunctionParameters
    
    /// Creates a new function declaration
    public init(name: String, description: String, parameters: FunctionParameters) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

/// Function parameters
public struct FunctionParameters: Codable, Equatable, Sendable {
    /// The type of the parameters (always "object")
    public let type: String
    
    /// The properties of the parameters
    public let properties: [String: ParameterProperty]
    
    /// Required parameter names
    public let required: [String]?
    
    /// Creates new function parameters
    public init(properties: [String: ParameterProperty], required: [String]? = nil) {
        self.type = "object"
        self.properties = properties
        self.required = required
    }
}

/// Parameter property
public indirect enum ParameterProperty: Codable, Equatable, Sendable {
    case string(description: String?, enum: [String]?)
    case number(description: String?)
    case integer(description: String?)
    case boolean(description: String?)
    case array(description: String?, items: ParameterProperty)
    case object(description: String?, properties: [String: ParameterProperty]?, required: [String]?)
    
    private enum CodingKeys: String, CodingKey {
        case type, description, `enum`, items, properties, required
    }
    
    public var type: String {
        switch self {
        case .string: return "string"
        case .number: return "number"
        case .integer: return "integer"
        case .boolean: return "boolean"
        case .array: return "array"
        case .object: return "object"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let description = try container.decodeIfPresent(String.self, forKey: .description)
        
        switch type {
        case "string":
            let enumValues = try container.decodeIfPresent([String].self, forKey: .enum)
            self = .string(description: description, enum: enumValues)
        case "number":
            self = .number(description: description)
        case "integer":
            self = .integer(description: description)
        case "boolean":
            self = .boolean(description: description)
        case "array":
            let items = try container.decode(ParameterProperty.self, forKey: .items)
            self = .array(description: description, items: items)
        case "object":
            let properties = try container.decodeIfPresent([String: ParameterProperty].self, forKey: .properties)
            let required = try container.decodeIfPresent([String].self, forKey: .required)
            self = .object(description: description, properties: properties, required: required)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        switch self {
        case .string(let description, let enumValues):
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(enumValues, forKey: .enum)
        case .number(let description), .integer(let description), .boolean(let description):
            try container.encodeIfPresent(description, forKey: .description)
        case .array(let description, let items):
            try container.encodeIfPresent(description, forKey: .description)
            try container.encode(items, forKey: .items)
        case .object(let description, let properties, let required):
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(properties, forKey: .properties)
            try container.encodeIfPresent(required, forKey: .required)
        }
    }
}

// Convenience initializers for backwards compatibility
extension ParameterProperty {
    public init(type: String, description: String? = nil, enum: [String]? = nil) {
        switch type {
        case "string":
            self = .string(description: description, enum: `enum`)
        case "number":
            self = .number(description: description)
        case "integer":
            self = .integer(description: description)
        case "boolean":
            self = .boolean(description: description)
        default:
            self = .string(description: description, enum: nil)
        }
    }
}

/// URL context for retrieving and analyzing content from URLs
public struct URLContext: Codable, Equatable, Sendable {
    /// The URLs to retrieve content from
    public let urls: [String]
    
    /// Creates a new URL context
    /// - Parameter urls: The URLs to retrieve content from
    public init(urls: [String]) {
        self.urls = urls
    }
}

/// Tool configuration
public struct ToolConfig: Codable, Equatable, Sendable {
    /// Function calling configuration
    public let functionCallingConfig: FunctionCallingConfig
    
    /// Creates a new tool configuration
    /// - Parameter functionCallingConfig: Function calling configuration
    public init(functionCallingConfig: FunctionCallingConfig) {
        self.functionCallingConfig = functionCallingConfig
    }
}

/// Function calling configuration
public struct FunctionCallingConfig: Codable, Equatable, Sendable {
    /// The mode for function calling
    public let mode: Mode
    
    /// Allowed function names when mode is ANY
    public let allowedFunctionNames: [String]?
    
    /// Function calling modes
    public enum Mode: String, Codable, Equatable, Sendable {
        case auto = "AUTO"
        case any = "ANY"
        case none = "NONE"
    }
    
    /// Creates a new function calling configuration
    /// - Parameters:
    ///   - mode: The mode for function calling
    ///   - allowedFunctionNames: Allowed function names when mode is ANY
    public init(mode: Mode, allowedFunctionNames: [String]? = nil) {
        self.mode = mode
        self.allowedFunctionNames = allowedFunctionNames
    }
}

/// Safety setting
public struct SafetySetting: Codable, Equatable, Sendable {
    /// The category to configure
    public let category: HarmCategory
    
    /// The threshold for blocking
    public let threshold: HarmBlockThreshold
    
    /// Creates a new safety setting
    /// - Parameters:
    ///   - category: The category to configure
    ///   - threshold: The threshold for blocking
    public init(category: HarmCategory, threshold: HarmBlockThreshold) {
        self.category = category
        self.threshold = threshold
    }
}

/// Harm categories
public enum HarmCategory: String, Codable, Equatable, Sendable {
    case harassment = "HARM_CATEGORY_HARASSMENT"
    case hateSpeech = "HARM_CATEGORY_HATE_SPEECH"
    case sexuallyExplicit = "HARM_CATEGORY_SEXUALLY_EXPLICIT"
    case dangerousContent = "HARM_CATEGORY_DANGEROUS_CONTENT"
}

/// Harm block thresholds
public enum HarmBlockThreshold: String, Codable, Equatable, Sendable {
    case blockNone = "BLOCK_NONE"
    case blockOnlyHigh = "BLOCK_ONLY_HIGH"
    case blockMediumAndAbove = "BLOCK_MEDIUM_AND_ABOVE"
    case blockLowAndAbove = "BLOCK_LOW_AND_ABOVE"
}

/// Empty object for tools without parameters
private struct EmptyObject: Codable, Equatable {}