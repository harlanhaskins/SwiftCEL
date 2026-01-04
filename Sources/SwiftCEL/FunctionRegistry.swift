import Foundation

// MARK: - Value Type

/// Type identifier for CEL values
public enum ValueType: CustomStringConvertible {
    case string
    case int
    case uint
    case double
    case bool
    case bytes
    case list
    case map
    case null
    case any

    public var description: String {
        switch self {
        case .string: "string"
        case .int: "int"
        case .uint: "uint"
        case .double: "double"
        case .bool: "bool"
        case .bytes: "bytes"
        case .list: "list"
        case .map: "map"
        case .null: "null"
        case .any: "any"
        }
    }
}

// MARK: - Function Registry

/// Registry for CEL functions (both global functions and type methods)
public struct FunctionRegistry {
    /// Callback type for function implementations
    public typealias FunctionCallback = ([Value]) throws -> Value

    private var globalFunctions: [String: FunctionDefinition] = [:]
    private var typeMethods: [ValueType: [String: FunctionDefinition]] = [:]

    public init() {
        registerStandardLibrary()
    }

    // MARK: - Registration

    /// Register a global function
    public mutating func registerGlobalFunction(
        name: String,
        parameters: [ParameterDefinition],
        callback: @escaping FunctionCallback
    ) {
        globalFunctions[name] = FunctionDefinition(
            name: name,
            parameters: parameters,
            callback: callback
        )
    }

    /// Register a method on a specific type
    public mutating func registerMethod(
        type: ValueType,
        methodName: String,
        parameters: [ParameterDefinition],
        callback: @escaping FunctionCallback
    ) {
        if typeMethods[type] == nil {
            typeMethods[type] = [:]
        }
        typeMethods[type]![methodName] = FunctionDefinition(
            name: methodName,
            parameters: parameters,
            callback: callback
        )
    }

    // MARK: - Lookup

    /// Look up a global function by name
    public func lookupGlobalFunction(_ name: String) -> FunctionDefinition? {
        return globalFunctions[name]
    }

    /// Look up a method on a specific type
    public func lookupMethod(type: ValueType, methodName: String) -> FunctionDefinition? {
        return typeMethods[type]?[methodName]
    }

    // MARK: - Standard Library

    private mutating func registerStandardLibrary() {
        // Global size() function
        registerGlobalFunction(name: "size", parameters: [
            ParameterDefinition(name: "value", type: .any)
        ]) { args in
            let value = args[0]
            if let str = value.asString {
                return .int(Int64(str.count))
            } else if let list = value.asList {
                return .int(Int64(list.count))
            } else if let map = value.asMap {
                return .int(Int64(map.count))
            } else {
                throw EvalError.typeMismatch("size() requires string, list, or map")
            }
        }

        // String methods
        registerMethod(type: .string, methodName: "contains", parameters: [
            ParameterDefinition(name: "self", type: .string),
            ParameterDefinition(name: "substring", type: .string)
        ]) { args in
            let str = args[0].asString!
            let substring = args[1].asString!
            return .bool(str.contains(substring))
        }

        registerMethod(type: .string, methodName: "startsWith", parameters: [
            ParameterDefinition(name: "self", type: .string),
            ParameterDefinition(name: "prefix", type: .string)
        ]) { args in
            let str = args[0].asString!
            let prefix = args[1].asString!
            return .bool(str.hasPrefix(prefix))
        }

        registerMethod(type: .string, methodName: "endsWith", parameters: [
            ParameterDefinition(name: "self", type: .string),
            ParameterDefinition(name: "suffix", type: .string)
        ]) { args in
            let str = args[0].asString!
            let suffix = args[1].asString!
            return .bool(str.hasSuffix(suffix))
        }

        registerMethod(type: .string, methodName: "matches", parameters: [
            ParameterDefinition(name: "self", type: .string),
            ParameterDefinition(name: "pattern", type: .string)
        ]) { args in
            let str = args[0].asString!
            let pattern = args[1].asString!

            do {
                let regex = try Regex(pattern)
                return .bool(str.contains(regex))
            } catch {
                throw EvalError.invalidOperation("Invalid regex pattern: \(pattern)")
            }
        }

        registerMethod(type: .string, methodName: "size", parameters: [
            ParameterDefinition(name: "self", type: .string)
        ]) { args in
            let str = args[0].asString!
            return .int(Int64(str.count))
        }

        // List methods
        registerMethod(type: .list, methodName: "size", parameters: [
            ParameterDefinition(name: "self", type: .list)
        ]) { args in
            let list = args[0].asList!
            return .int(Int64(list.count))
        }

        // Map methods
        registerMethod(type: .map, methodName: "size", parameters: [
            ParameterDefinition(name: "self", type: .map)
        ]) { args in
            let map = args[0].asMap!
            return .int(Int64(map.count))
        }
    }
}

// MARK: - Function Definition

/// Definition of a CEL function
public struct FunctionDefinition {
    public let name: String
    public let parameters: [ParameterDefinition]
    public let callback: FunctionRegistry.FunctionCallback

    public init(
        name: String,
        parameters: [ParameterDefinition],
        callback: @escaping FunctionRegistry.FunctionCallback
    ) {
        self.name = name
        self.parameters = parameters
        self.callback = callback
    }

    /// Validate arguments and execute the callback
    public func call(with args: [Value]) throws -> Value {
        // Validate argument count
        guard args.count == parameters.count else {
            throw EvalError.invalidOperation("\(name)() requires exactly \(parameters.count) argument(s), got \(args.count)")
        }

        // Validate argument types
        for (index, param) in parameters.enumerated() {
            guard validateType(args[index], matches: param.type) else {
                throw EvalError.typeMismatch("\(name)() parameter '\(param.name)' expects \(param.type), got \(args[index])")
            }
        }

        // Execute callback
        return try callback(args)
    }

    /// Check if a value matches the expected type
    private func validateType(_ value: Value, matches expectedType: ValueType) -> Bool {
        // .any accepts anything
        if expectedType == .any {
            return true
        }

        // Check specific type
        switch (value, expectedType) {
        case (.string, .string): return true
        case (.int, .int): return true
        case (.uint, .uint): return true
        case (.double, .double): return true
        case (.bool, .bool): return true
        case (.bytes, .bytes): return true
        case (.list, .list): return true
        case (.map, .map): return true
        case (.null, .null): return true
        default: return false
        }
    }
}

// MARK: - Parameter Definition

/// Definition of a function parameter
public struct ParameterDefinition {
    public let name: String
    public let type: ParameterType

    public init(name: String, type: ParameterType) {
        self.name = name
        self.type = type
    }
}

/// Parameter type constraint (reuses ValueType)
public typealias ParameterType = ValueType
