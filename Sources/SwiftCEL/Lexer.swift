import Foundation

// MARK: - Token

public enum Token: Equatable, Sendable {
    // Literals
    case int(Int64)
    case uint(UInt64)
    case double(Double)
    case string(String)
    case bytes(Data)
    case bool(Bool)
    case null

    // Identifiers
    case identifier(String)

    // Operators - Arithmetic
    case plus      // +
    case minus     // -
    case star      // *
    case slash     // /
    case percent   // %

    // Operators - Comparison
    case eq        // ==
    case neq       // !=
    case lt        // <
    case lte       // <=
    case gt        // >
    case gte       // >=

    // Operators - Logical
    case and       // &&
    case or        // ||
    case not       // !

    // Keywords
    case `in`       // in

    // Punctuation
    case dot            // .
    case comma          // ,
    case colon          // :
    case questionMark   // ?
    case lparen         // (
    case rparen         // )
    case lbracket       // [
    case rbracket       // ]
    case lbrace         // {
    case rbrace         // }

    // Special
    case eof
}

// MARK: - Lexer Error

public enum LexerError: Error, CustomStringConvertible {
    case unexpectedCharacter(Character, position: Int)
    case unterminatedString(position: Int)
    case invalidNumber(String, position: Int)
    case invalidEscape(String, position: Int)

    public var description: String {
        switch self {
        case .unexpectedCharacter(let char, let pos):
            return "Unexpected character '\(char)' at position \(pos)"
        case .unterminatedString(let pos):
            return "Unterminated string at position \(pos)"
        case .invalidNumber(let num, let pos):
            return "Invalid number '\(num)' at position \(pos)"
        case .invalidEscape(let esc, let pos):
            return "Invalid escape sequence '\(esc)' at position \(pos)"
        }
    }
}

// MARK: - Lexer

public final class Lexer {
    private let input: String
    private let characters: [Character]
    private var position: Int = 0

    public init(input: String) {
        self.input = input
        self.characters = Array(input)
    }

    public func tokenize() throws -> [Token] {
        var tokens: [Token] = []

        while !isAtEnd() {
            skipWhitespace()
            if isAtEnd() { break }

            let token = try nextToken()
            tokens.append(token)
        }

        tokens.append(.eof)
        return tokens
    }

    private func nextToken() throws -> Token {
        let char = peek()

        // Numbers
        if char.isNumber {
            return try scanNumber()
        }

        // Strings
        if char == "\"" || char == "'" {
            return try scanString(quote: char)
        }

        // Raw strings
        if (char == "r" || char == "R") && (peekNext() == "\"" || peekNext() == "'") {
            advance() // consume 'r'
            let quote = peek()
            return try scanString(quote: quote, raw: true)
        }

        // Identifiers and keywords
        if char.isLetter || char == "_" {
            return scanIdentifierOrKeyword()
        }

        // Operators and punctuation
        return try scanOperatorOrPunctuation()
    }

    // MARK: - Number Scanning

    private func scanNumber() throws -> Token {
        let start = position

        // Check for hex
        if peek() == "0" && (peekNext() == "x" || peekNext() == "X") {
            advance() // 0
            advance() // x
            return try scanHexNumber()
        }

        // Scan integer part
        var numberString = ""
        while !isAtEnd() && peek().isNumber {
            numberString.append(advance())
        }

        // Check for unsigned suffix
        if peek() == "u" {
            advance()
            guard let value = UInt64(numberString) else {
                throw LexerError.invalidNumber(numberString, position: start)
            }
            return .uint(value)
        }

        // Check for decimal point or exponent
        // Only treat '.' as decimal if followed by a digit
        let hasDecimal = peek() == "." && peekNext()?.isNumber == true
        let hasExponent = peek() == "e" || peek() == "E"

        if hasDecimal || hasExponent {
            // Floating point
            if hasDecimal {
                numberString.append(advance()) // .
                while !isAtEnd() && peek().isNumber {
                    numberString.append(advance())
                }
            }

            if peek() == "e" || peek() == "E" {
                numberString.append(advance()) // e
                if peek() == "+" || peek() == "-" {
                    numberString.append(advance())
                }
                while !isAtEnd() && peek().isNumber {
                    numberString.append(advance())
                }
            }

            guard let value = Double(numberString) else {
                throw LexerError.invalidNumber(numberString, position: start)
            }
            return .double(value)
        } else {
            // Integer
            guard let value = Int64(numberString) else {
                throw LexerError.invalidNumber(numberString, position: start)
            }
            return .int(value)
        }
    }

    private func scanHexNumber() throws -> Token {
        let start = position
        var hexString = ""

        while !isAtEnd() && peek().isHexDigit {
            hexString.append(advance())
        }

        guard let value = Int64(hexString, radix: 16) else {
            throw LexerError.invalidNumber("0x" + hexString, position: start)
        }

        return .int(value)
    }

    // MARK: - String Scanning

    private func scanString(quote: Character, raw: Bool = false) throws -> Token {
        let start = position
        advance() // opening quote

        var result = ""

        while !isAtEnd() && peek() != quote {
            if !raw && peek() == "\\" {
                advance() // backslash
                if isAtEnd() {
                    throw LexerError.unterminatedString(position: start)
                }
                let escaped = try scanEscapeSequence()
                result.append(escaped)
            } else {
                result.append(advance())
            }
        }

        if isAtEnd() {
            throw LexerError.unterminatedString(position: start)
        }

        advance() // closing quote
        return .string(result)
    }

    private func scanEscapeSequence() throws -> Character {
        let char = advance()

        switch char {
        case "n": return "\n"
        case "t": return "\t"
        case "r": return "\r"
        case "\\": return "\\"
        case "\"": return "\""
        case "'": return "'"
        case "0": return "\0"
        default:
            throw LexerError.invalidEscape("\\\(char)", position: position - 1)
        }
    }

    // MARK: - Identifier Scanning

    private func scanIdentifierOrKeyword() -> Token {
        var identifier = ""

        while !isAtEnd() && (peek().isLetter || peek().isNumber || peek() == "_") {
            identifier.append(advance())
        }

        // Check for keywords
        switch identifier {
        case "true": return .bool(true)
        case "false": return .bool(false)
        case "null": return .null
        case "in": return .in
        default: return .identifier(identifier)
        }
    }

    // MARK: - Operator Scanning

    private func scanOperatorOrPunctuation() throws -> Token {
        let char = advance()

        switch char {
        // Single character tokens
        case "+": return .plus
        case "*": return .star
        case "/": return .slash
        case "%": return .percent
        case ".": return .dot
        case ",": return .comma
        case ":": return .colon
        case "?": return .questionMark
        case "(": return .lparen
        case ")": return .rparen
        case "[": return .lbracket
        case "]": return .rbracket
        case "{": return .lbrace
        case "}": return .rbrace

        // Minus or negative number (handled in scanNumber)
        case "-":
            return .minus

        // Multi-character operators
        case "=":
            if peek() == "=" {
                advance()
                return .eq
            }
            throw LexerError.unexpectedCharacter(char, position: position - 1)

        case "!":
            if peek() == "=" {
                advance()
                return .neq
            }
            return .not

        case "<":
            if peek() == "=" {
                advance()
                return .lte
            }
            return .lt

        case ">":
            if peek() == "=" {
                advance()
                return .gte
            }
            return .gt

        case "&":
            if peek() == "&" {
                advance()
                return .and
            }
            throw LexerError.unexpectedCharacter(char, position: position - 1)

        case "|":
            if peek() == "|" {
                advance()
                return .or
            }
            throw LexerError.unexpectedCharacter(char, position: position - 1)

        default:
            throw LexerError.unexpectedCharacter(char, position: position - 1)
        }
    }

    // MARK: - Helper Methods

    private func peek() -> Character {
        guard position < characters.count else {
            return "\0"
        }
        return characters[position]
    }

    private func peekNext() -> Character? {
        guard position + 1 < characters.count else {
            return nil
        }
        return characters[position + 1]
    }

    @discardableResult
    private func advance() -> Character {
        let char = peek()
        position += 1
        return char
    }

    private func isAtEnd() -> Bool {
        position >= characters.count
    }

    private func skipWhitespace() {
        while !isAtEnd() && peek().isWhitespace {
            advance()
        }
    }
}

// MARK: - Character Extensions

extension Character {
    fileprivate var isHexDigit: Bool {
        isNumber || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}
