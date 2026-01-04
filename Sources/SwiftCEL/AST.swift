import Foundation

// MARK: - Source Location

public struct SourceRange: Sendable {
    public let start: Int  // Character offset in source
    public let end: Int

    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }
}

// MARK: - Expression Protocol

public protocol Expr: Sendable {
    var sourceRange: SourceRange { get }
}

// MARK: - Literals

public struct LiteralExpr: Expr {
    public let value: Literal
    public let sourceRange: SourceRange

    public init(value: Literal, sourceRange: SourceRange) {
        self.value = value
        self.sourceRange = sourceRange
    }
}

public enum Literal: Sendable {
    case int(Int64)
    case uint(UInt64)
    case double(Double)
    case string(String)
    case bytes(Data)
    case bool(Bool)
    case null
}

// MARK: - Identifiers

public struct IdentExpr: Expr {
    public let name: String
    public let sourceRange: SourceRange

    public init(name: String, sourceRange: SourceRange) {
        self.name = name
        self.sourceRange = sourceRange
    }
}

// MARK: - Member Access

public struct SelectExpr: Expr {
    public let operand: any Expr
    public let field: String
    public let sourceRange: SourceRange

    public init(operand: any Expr, field: String, sourceRange: SourceRange) {
        self.operand = operand
        self.field = field
        self.sourceRange = sourceRange
    }
}

// MARK: - Indexing

public struct IndexExpr: Expr {
    public let operand: any Expr
    public let index: any Expr
    public let sourceRange: SourceRange

    public init(operand: any Expr, index: any Expr, sourceRange: SourceRange) {
        self.operand = operand
        self.index = index
        self.sourceRange = sourceRange
    }
}

// MARK: - Function Calls

public struct CallExpr: Expr {
    public let function: String
    public let args: [any Expr]
    public let sourceRange: SourceRange

    public init(function: String, args: [any Expr], sourceRange: SourceRange) {
        self.function = function
        self.args = args
        self.sourceRange = sourceRange
    }
}

public struct MemberCallExpr: Expr {
    public let operand: any Expr
    public let method: String
    public let args: [any Expr]
    public let sourceRange: SourceRange

    public init(operand: any Expr, method: String, args: [any Expr], sourceRange: SourceRange) {
        self.operand = operand
        self.method = method
        self.args = args
        self.sourceRange = sourceRange
    }
}

// MARK: - Operators

public struct UnaryExpr: Expr {
    public let op: UnaryOp
    public let operand: any Expr
    public let sourceRange: SourceRange

    public init(op: UnaryOp, operand: any Expr, sourceRange: SourceRange) {
        self.op = op
        self.operand = operand
        self.sourceRange = sourceRange
    }
}

public enum UnaryOp: String, Sendable {
    case not = "!"
    case negate = "-"
}

public struct BinaryExpr: Expr {
    public let op: BinaryOp
    public let lhs: any Expr
    public let rhs: any Expr
    public let sourceRange: SourceRange

    public init(op: BinaryOp, lhs: any Expr, rhs: any Expr, sourceRange: SourceRange) {
        self.op = op
        self.lhs = lhs
        self.rhs = rhs
        self.sourceRange = sourceRange
    }
}

public enum BinaryOp: String, Sendable {
    // Arithmetic
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"

    // Comparison
    case equal = "=="
    case notEqual = "!="
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="

    // Logical
    case and = "&&"
    case or = "||"

    // Membership
    case `in` = "in"
}

public struct TernaryExpr: Expr {
    public let condition: any Expr
    public let trueExpr: any Expr
    public let falseExpr: any Expr
    public let sourceRange: SourceRange

    public init(condition: any Expr, trueExpr: any Expr, falseExpr: any Expr, sourceRange: SourceRange) {
        self.condition = condition
        self.trueExpr = trueExpr
        self.falseExpr = falseExpr
        self.sourceRange = sourceRange
    }
}

// MARK: - Collections

public struct ListExpr: Expr {
    public let elements: [any Expr]
    public let sourceRange: SourceRange

    public init(elements: [any Expr], sourceRange: SourceRange) {
        self.elements = elements
        self.sourceRange = sourceRange
    }
}

public struct MapExpr: Expr {
    public let entries: [(key: any Expr, value: any Expr)]
    public let sourceRange: SourceRange

    public init(entries: [(key: any Expr, value: any Expr)], sourceRange: SourceRange) {
        self.entries = entries
        self.sourceRange = sourceRange
    }
}

