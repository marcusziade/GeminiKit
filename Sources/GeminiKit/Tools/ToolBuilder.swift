import Foundation

/// Builder for creating function declarations
public final class FunctionBuilder {
    private var name: String
    private var description: String
    private var properties: [String: ParameterProperty] = [:]
    private var required: [String] = []
    
    /// Creates a new function builder
    /// - Parameters:
    ///   - name: The name of the function
    ///   - description: Description of what the function does
    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
    
    /// Adds a string parameter
    /// - Parameters:
    ///   - name: Parameter name
    ///   - description: Parameter description
    ///   - enumValues: Optional enum values
    ///   - required: Whether the parameter is required
    /// - Returns: Self for chaining
    @discardableResult
    public func addString(
        _ name: String,
        description: String? = nil,
        enumValues: [String]? = nil,
        required: Bool = false
    ) -> FunctionBuilder {
        properties[name] = .string(description: description, enum: enumValues)
        if required {
            self.required.append(name)
        }
        return self
    }
    
    /// Adds an integer parameter
    /// - Parameters:
    ///   - name: Parameter name
    ///   - description: Parameter description
    ///   - required: Whether the parameter is required
    /// - Returns: Self for chaining
    @discardableResult
    public func addInteger(
        _ name: String,
        description: String? = nil,
        required: Bool = false
    ) -> FunctionBuilder {
        properties[name] = .integer(description: description)
        if required {
            self.required.append(name)
        }
        return self
    }
    
    /// Adds a number parameter
    /// - Parameters:
    ///   - name: Parameter name
    ///   - description: Parameter description
    ///   - required: Whether the parameter is required
    /// - Returns: Self for chaining
    @discardableResult
    public func addNumber(
        _ name: String,
        description: String? = nil,
        required: Bool = false
    ) -> FunctionBuilder {
        properties[name] = .number(description: description)
        if required {
            self.required.append(name)
        }
        return self
    }
    
    /// Adds a boolean parameter
    /// - Parameters:
    ///   - name: Parameter name
    ///   - description: Parameter description
    ///   - required: Whether the parameter is required
    /// - Returns: Self for chaining
    @discardableResult
    public func addBoolean(
        _ name: String,
        description: String? = nil,
        required: Bool = false
    ) -> FunctionBuilder {
        properties[name] = .boolean(description: description)
        if required {
            self.required.append(name)
        }
        return self
    }
    
    /// Adds an array parameter
    /// - Parameters:
    ///   - name: Parameter name
    ///   - itemType: The type of items in the array
    ///   - description: Parameter description
    ///   - required: Whether the parameter is required
    /// - Returns: Self for chaining
    @discardableResult
    public func addArray(
        _ name: String,
        itemType: String,
        description: String? = nil,
        required: Bool = false
    ) -> FunctionBuilder {
        let itemProperty: ParameterProperty
        switch itemType {
        case "string": itemProperty = .string(description: nil, enum: nil)
        case "number": itemProperty = .number(description: nil)
        case "integer": itemProperty = .integer(description: nil)
        case "boolean": itemProperty = .boolean(description: nil)
        default: itemProperty = .string(description: nil, enum: nil)
        }
        
        properties[name] = .array(description: description, items: itemProperty)
        if required {
            self.required.append(name)
        }
        return self
    }
    
    /// Builds the function declaration
    /// - Returns: The function declaration
    public func build() -> FunctionDeclaration {
        FunctionDeclaration(
            name: name,
            description: description,
            parameters: FunctionParameters(
                properties: properties,
                required: required.isEmpty ? nil : required
            )
        )
    }
}

/// Tool configuration builder
public final class ToolConfigBuilder {
    private var mode: FunctionCallingConfig.Mode = .auto
    private var allowedFunctions: [String]?
    
    /// Creates a new tool config builder
    public init() {}
    
    /// Sets the function calling mode
    /// - Parameter mode: The mode to use
    /// - Returns: Self for chaining
    @discardableResult
    public func mode(_ mode: FunctionCallingConfig.Mode) -> ToolConfigBuilder {
        self.mode = mode
        return self
    }
    
    /// Sets allowed function names (only used with .any mode)
    /// - Parameter functions: The allowed function names
    /// - Returns: Self for chaining
    @discardableResult
    public func allowedFunctions(_ functions: [String]) -> ToolConfigBuilder {
        self.allowedFunctions = functions
        return self
    }
    
    /// Builds the tool configuration
    /// - Returns: The tool configuration
    public func build() -> ToolConfig {
        ToolConfig(
            functionCallingConfig: FunctionCallingConfig(
                mode: mode,
                allowedFunctionNames: allowedFunctions
            )
        )
    }
}

/// Convenience methods for creating tools
public enum Tools {
    /// Creates a function declaration tool
    /// - Parameter functions: The function declarations
    /// - Returns: A tool with function declarations
    public static func functions(_ functions: [FunctionDeclaration]) -> Tool {
        .functionDeclarations(functions)
    }
    
    /// Creates a code execution tool
    /// - Returns: A code execution tool
    public static func codeExecution() -> Tool {
        .codeExecution
    }
    
    /// Creates a Google Search grounding tool
    /// - Returns: A Google Search tool
    public static func googleSearch() -> Tool {
        .googleSearch
    }
    
    /// Creates a URL context tool
    /// - Parameter urls: The URLs to retrieve content from
    /// - Returns: A URL context tool
    public static func urlContext(urls: [String]) -> Tool {
        .urlContext(URLContext(urls: urls))
    }
}