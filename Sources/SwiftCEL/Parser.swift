import Foundation

// MARK: - Parser Error

public enum ParserError: Error, CustomStringConvertible {
    case unexpectedToken(expected: String, got: Token, position: Int)
    case unexpectedEndOfInput
    case invalidExpression(String)

    public var description: String {
        switch self {
        case .unexpectedToken(let expected, let got, let pos):
            return "Expected \(expected) but got \(got) at position \(pos)"
        case .unexpectedEndOfInput:
            return "Unexpected end of input"
        case .invalidExpression(let msg):
            return "Invalid expression: \(msg)"
        }
    }
}

// MARK: - Parser

public final class Parser {
    private var tokens: [Token]
    private var position: Int = 0

    private init(tokens: [Token]) {
        self.tokens = tokens
    }

    /// Parse a CEL expression from a string
    public static func parse(_ input: String) throws -> any Expr {
        let lexer = Lexer(input: input)
        let tokens = try lexer.tokenize()
        let parser = Parser(tokens: tokens)
        return try parser.parseExpression()
    }

    // MARK: - Expression Parsing

    /// expr → ternary
    private func parseExpression() throws -> any Expr {
        return try parseTernary()
    }

    /// ternary → logicalOr ('?' expr ':' expr)?
    private func parseTernary() throws -> any Expr {
        let start = currentPosition()
        var expr = try parseLogicalOr()

        if match(.questionMark) {
            let trueExpr = try parseExpression()
            try consume(.colon, "Expected ':' in ternary expression")
            let falseExpr = try parseExpression()

            expr = TernaryExpr(
                condition: expr,
                trueExpr: trueExpr,
                falseExpr: falseExpr,
                sourceRange: sourceRange(from: start)
            )
        }

        return expr
    }

    /// logicalOr → logicalAnd ('||' logicalAnd)*
    private func parseLogicalOr() throws -> any Expr {
        let start = currentPosition()
        var expr = try parseLogicalAnd()

        while match(.or) {
            let rhs = try parseLogicalAnd()
            expr = BinaryExpr(
                op: .or,
                lhs: expr,
                rhs: rhs,
                sourceRange: sourceRange(from: start)
            )
        }

        return expr
    }

    /// logicalAnd → relation ('&&' relation)*
    private func parseLogicalAnd() throws -> any Expr {
        let start = currentPosition()
        var expr = try parseRelation()

        while match(.and) {
            let rhs = try parseRelation()
            expr = BinaryExpr(
                op: .and,
                lhs: expr,
                rhs: rhs,
                sourceRange: sourceRange(from: start)
            )
        }

        return expr
    }

    /// relation → addition (relOp addition)?
    private func parseRelation() throws -> any Expr {
        let start = currentPosition()
        var expr = try parseAddition()

        // Relational operators
        if let op = matchRelationalOp() {
            let rhs = try parseAddition()
            expr = BinaryExpr(
                op: op,
                lhs: expr,
                rhs: rhs,
                sourceRange: sourceRange(from: start)
            )
        }

        // 'in' operator
        if match(.in) {
            let rhs = try parseAddition()
            expr = BinaryExpr(
                op: .in,
                lhs: expr,
                rhs: rhs,
                sourceRange: sourceRange(from: start)
            )
        }

        return expr
    }

    /// addition → multiplication (('+' | '-') multiplication)*
    private func parseAddition() throws -> any Expr {
        let start = currentPosition()
        var expr = try parseMultiplication()

        while true {
            if match(.plus) {
                let rhs = try parseMultiplication()
                expr = BinaryExpr(
                    op: .add,
                    lhs: expr,
                    rhs: rhs,
                    sourceRange: sourceRange(from: start)
                )
            } else if match(.minus) {
                let rhs = try parseMultiplication()
                expr = BinaryExpr(
                    op: .subtract,
                    lhs: expr,
                    rhs: rhs,
                    sourceRange: sourceRange(from: start)
                )
            } else {
                break
            }
        }

        return expr
    }

    /// multiplication → unary (('*' | '/' | '%') unary)*
    private func parseMultiplication() throws -> any Expr {
        let start = currentPosition()
        var expr = try parseUnary()

        while true {
            if match(.star) {
                let rhs = try parseUnary()
                expr = BinaryExpr(
                    op: .multiply,
                    lhs: expr,
                    rhs: rhs,
                    sourceRange: sourceRange(from: start)
                )
            } else if match(.slash) {
                let rhs = try parseUnary()
                expr = BinaryExpr(
                    op: .divide,
                    lhs: expr,
                    rhs: rhs,
                    sourceRange: sourceRange(from: start)
                )
            } else if match(.percent) {
                let rhs = try parseUnary()
                expr = BinaryExpr(
                    op: .modulo,
                    lhs: expr,
                    rhs: rhs,
                    sourceRange: sourceRange(from: start)
                )
            } else {
                break
            }
        }

        return expr
    }

    /// unary → ('!' | '-')? member
    private func parseUnary() throws -> any Expr {
        let start = currentPosition()

        if match(.not) {
            let operand = try parseUnary()
            return UnaryExpr(
                op: .not,
                operand: operand,
                sourceRange: sourceRange(from: start)
            )
        }

        if match(.minus) {
            let operand = try parseUnary()
            return UnaryExpr(
                op: .negate,
                operand: operand,
                sourceRange: sourceRange(from: start)
            )
        }

        return try parseMember()
    }

    /// member → primary ('.' ident | '[' expr ']' | '(' args ')')*
    private func parseMember() throws -> any Expr {
        let start = currentPosition()
        var expr = try parsePrimary()

        while true {
            if match(.dot) {
                // Member access or member call
                let fieldName = try consumeIdentifier()

                // Check if it's a method call
                if match(.lparen) {
                    let args = try parseArguments()
                    try consume(.rparen, "Expected ')' after arguments")

                    // All method calls (including macros) are parsed as MemberCallExpr
                    expr = MemberCallExpr(
                        operand: expr,
                        method: fieldName,
                        args: args,
                        sourceRange: sourceRange(from: start)
                    )
                } else {
                    // Member access
                    expr = SelectExpr(
                        operand: expr,
                        field: fieldName,
                        sourceRange: sourceRange(from: start)
                    )
                }
            } else if match(.lbracket) {
                // Index access
                let index = try parseExpression()
                try consume(.rbracket, "Expected ']' after index")

                expr = IndexExpr(
                    operand: expr,
                    index: index,
                    sourceRange: sourceRange(from: start)
                )
            } else if peek() == .lparen {
                // Function call (only for identifiers)
                if let ident = expr as? IdentExpr {
                    advance() // consume '('
                    let args = try parseArguments()
                    try consume(.rparen, "Expected ')' after arguments")

                    expr = CallExpr(
                        function: ident.name,
                        args: args,
                        sourceRange: sourceRange(from: start)
                    )
                } else {
                    break
                }
            } else {
                break
            }
        }

        return expr
    }

    /// primary → literal | ident | '(' expr ')' | '[' list ']' | '{' map '}'
    private func parsePrimary() throws -> any Expr {
        let start = currentPosition()
        let token = peek()

        // Literals
        if case .int(let value) = token {
            advance()
            return LiteralExpr(
                value: .int(value),
                sourceRange: sourceRange(from: start)
            )
        }

        if case .uint(let value) = token {
            advance()
            return LiteralExpr(
                value: .uint(value),
                sourceRange: sourceRange(from: start)
            )
        }

        if case .double(let value) = token {
            advance()
            return LiteralExpr(
                value: .double(value),
                sourceRange: sourceRange(from: start)
            )
        }

        if case .string(let value) = token {
            advance()
            return LiteralExpr(
                value: .string(value),
                sourceRange: sourceRange(from: start)
            )
        }

        if case .bool(let value) = token {
            advance()
            return LiteralExpr(
                value: .bool(value),
                sourceRange: sourceRange(from: start)
            )
        }

        if case .null = token {
            advance()
            return LiteralExpr(
                value: .null,
                sourceRange: sourceRange(from: start)
            )
        }

        // Identifier
        if case .identifier(let name) = token {
            advance()
            return IdentExpr(
                name: name,
                sourceRange: sourceRange(from: start)
            )
        }

        // Parenthesized expression
        if match(.lparen) {
            let expr = try parseExpression()
            try consume(.rparen, "Expected ')' after expression")
            return expr
        }

        // List literal
        if match(.lbracket) {
            var elements: [any Expr] = []

            if !check(.rbracket) {
                repeat {
                    elements.append(try parseExpression())
                } while match(.comma)
            }

            try consume(.rbracket, "Expected ']' after list elements")

            return ListExpr(
                elements: elements,
                sourceRange: sourceRange(from: start)
            )
        }

        // Map literal
        if match(.lbrace) {
            var entries: [(key: any Expr, value: any Expr)] = []

            if !check(.rbrace) {
                repeat {
                    let key = try parseExpression()
                    try consume(.colon, "Expected ':' after map key")
                    let value = try parseExpression()
                    entries.append((key: key, value: value))
                } while match(.comma)
            }

            try consume(.rbrace, "Expected '}' after map entries")

            return MapExpr(
                entries: entries,
                sourceRange: sourceRange(from: start)
            )
        }

        throw ParserError.unexpectedToken(
            expected: "expression",
            got: token,
            position: position
        )
    }

    // MARK: - Helper Methods

    private func parseArguments() throws -> [any Expr] {
        var args: [any Expr] = []

        if !check(.rparen) && !check(.rbracket) {
            repeat {
                args.append(try parseExpression())
            } while match(.comma)
        }

        return args
    }

    private func matchRelationalOp() -> BinaryOp? {
        if match(.eq) { return .equal }
        if match(.neq) { return .notEqual }
        if match(.lt) { return .lessThan }
        if match(.lte) { return .lessThanOrEqual }
        if match(.gt) { return .greaterThan }
        if match(.gte) { return .greaterThanOrEqual }
        return nil
    }

    private func match(_ token: Token) -> Bool {
        if check(token) {
            advance()
            return true
        }
        return false
    }

    private func check(_ token: Token) -> Bool {
        if isAtEnd() { return false }
        return tokens[position] == token
    }

    private func peek() -> Token {
        guard position < tokens.count else {
            return .eof
        }
        return tokens[position]
    }

    @discardableResult
    private func advance() -> Token {
        if !isAtEnd() {
            position += 1
        }
        return tokens[position - 1]
    }

    private func isAtEnd() -> Bool {
        return peek() == .eof
    }

    private func consume(_ token: Token, _ message: String) throws {
        if !check(token) {
            throw ParserError.unexpectedToken(
                expected: message,
                got: peek(),
                position: position
            )
        }
        advance()
    }

    private func consumeIdentifier() throws -> String {
        guard case .identifier(let name) = peek() else {
            throw ParserError.unexpectedToken(
                expected: "identifier",
                got: peek(),
                position: position
            )
        }
        advance()
        return name
    }

    private func currentPosition() -> Int {
        return position
    }

    private func sourceRange(from start: Int) -> SourceRange {
        return SourceRange(start: start, end: position)
    }
}
