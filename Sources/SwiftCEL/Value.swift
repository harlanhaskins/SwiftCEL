import Foundation

// MARK: - Value

/// Represents a runtime value in CEL
public enum Value: Sendable {
    case int(Int64)
    case uint(UInt64)
    case double(Double)
    case string(String)
    case bytes(Data)
    case bool(Bool)
    case null
    case list([Value])
    case map([String: Value])
}

// MARK: - Equatable

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.int(let a), .int(let b)):
            return a == b
        case (.uint(let a), .uint(let b)):
            return a == b
        case (.double(let a), .double(let b)):
            return a == b
        case (.string(let a), .string(let b)):
            return a == b
        case (.bytes(let a), .bytes(let b)):
            return a == b
        case (.bool(let a), .bool(let b)):
            return a == b
        case (.null, .null):
            return true
        case (.list(let a), .list(let b)):
            return a == b
        case (.map(let a), .map(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Type Checking

extension Value {
    public var isInt: Bool {
        if case .int = self { return true }
        return false
    }

    public var isUint: Bool {
        if case .uint = self { return true }
        return false
    }

    public var isDouble: Bool {
        if case .double = self { return true }
        return false
    }

    public var isString: Bool {
        if case .string = self { return true }
        return false
    }

    public var isBytes: Bool {
        if case .bytes = self { return true }
        return false
    }

    public var isBool: Bool {
        if case .bool = self { return true }
        return false
    }

    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    public var isList: Bool {
        if case .list = self { return true }
        return false
    }

    public var isMap: Bool {
        if case .map = self { return true }
        return false
    }
}

// MARK: - Value Extraction

extension Value {
    public var asInt: Int64? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }

    public var asUInt: UInt64? {
        if case .uint(let value) = self {
            return value
        }
        return nil
    }

    public var asDouble: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

    public var asString: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    public var asBytes: Data? {
        if case .bytes(let value) = self {
            return value
        }
        return nil
    }

    public var asBool: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }

    public var asList: [Value]? {
        if case .list(let value) = self {
            return value
        }
        return nil
    }

    public var asMap: [String: Value]? {
        if case .map(let value) = self {
            return value
        }
        return nil
    }
}

// MARK: - Truthiness

extension Value {
    /// Returns true if the value is considered truthy in CEL
    /// In CEL, only false and null are falsy
    public var isTruthy: Bool {
        switch self {
        case .bool(let b):
            return b
        case .null:
            return false
        default:
            return true
        }
    }
}

// MARK: - CustomStringConvertible

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int(let v):
            return "\(v)"
        case .uint(let v):
            return "\(v)u"
        case .double(let v):
            return "\(v)"
        case .string(let v):
            return "\"\(v)\""
        case .bytes(let v):
            return "b\"\(v.base64EncodedString())\""
        case .bool(let v):
            return v ? "true" : "false"
        case .null:
            return "null"
        case .list(let elements):
            let elementDescriptions = elements.map { $0.description }.joined(separator: ", ")
            return "[\(elementDescriptions)]"
        case .map(let entries):
            let entryDescriptions = entries.map { key, value in
                "\"\(key)\": \(value.description)"
            }.joined(separator: ", ")
            return "{\(entryDescriptions)}"
        }
    }
}
