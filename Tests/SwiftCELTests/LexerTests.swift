import Testing
@testable import SwiftCEL

@Suite("Lexer Tests")
struct LexerTests {

    // MARK: - Literals

    @Test("Integer literals")
    func testIntegerLiterals() throws {
        let tests: [(String, Int64)] = [
            ("0", 0),
            ("42", 42),
            ("123456789", 123456789)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            #expect(tokens.count == 2) // number + EOF
            guard case .int(let value) = tokens[0] else {
                Issue.record("Expected int token")
                return
            }
            #expect(value == expected)
        }
    }

    @Test("Hexadecimal literals")
    func testHexLiterals() throws {
        let tests: [(String, Int64)] = [
            ("0x0", 0),
            ("0x10", 16),
            ("0xFF", 255),
            ("0xDEADBEEF", 0xDEADBEEF)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            guard case .int(let value) = tokens[0] else {
                Issue.record("Expected int token")
                return
            }
            #expect(value == expected)
        }
    }

    @Test("Unsigned integer literals")
    func testUnsignedLiterals() throws {
        let tests: [(String, UInt64)] = [
            ("0u", 0),
            ("42u", 42),
            ("18446744073709551615u", UInt64.max)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            guard case .uint(let value) = tokens[0] else {
                Issue.record("Expected uint token")
                return
            }
            #expect(value == expected)
        }
    }

    @Test("Double literals")
    func testDoubleLiterals() throws {
        let tests: [(String, Double)] = [
            ("0.0", 0.0),
            ("3.14", 3.14),
            ("1e10", 1e10),
            ("1.5e-5", 1.5e-5)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            guard case .double(let value) = tokens[0] else {
                Issue.record("Expected double token")
                return
            }
            #expect(value == expected)
        }
    }

    @Test("String literals")
    func testStringLiterals() throws {
        let tests: [(String, String)] = [
            ("\"hello\"", "hello"),
            ("'world'", "world"),
            ("\"hello\\nworld\"", "hello\nworld"),
            ("\"\\\"quoted\\\"\"", "\"quoted\""),
            ("r\"raw\\nstring\"", "raw\\nstring"),  // Raw string
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            guard case .string(let value) = tokens[0] else {
                Issue.record("Expected string token")
                return
            }
            #expect(value == expected)
        }
    }

    @Test("Boolean literals")
    func testBooleanLiterals() throws {
        let trueTests = ["true"]
        let falseTests = ["false"]

        for input in trueTests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            guard case .bool(let value) = tokens[0] else {
                Issue.record("Expected bool token")
                return
            }
            #expect(value == true)
        }

        for input in falseTests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            guard case .bool(let value) = tokens[0] else {
                Issue.record("Expected bool token")
                return
            }
            #expect(value == false)
        }
    }

    @Test("Null literal")
    func testNullLiteral() throws {
        let lexer = Lexer(input: "null")
        let tokens = try lexer.tokenize()
        guard case .null = tokens[0] else {
            Issue.record("Expected null token")
            return
        }
    }

    // MARK: - Identifiers

    @Test("Identifiers")
    func testIdentifiers() throws {
        let tests = [
            "x",
            "name",
            "firstName",
            "_private",
            "value123",
            "_123"
        ]

        for input in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            guard case .identifier(let name) = tokens[0] else {
                Issue.record("Expected identifier token")
                return
            }
            #expect(name == input)
        }
    }

    // MARK: - Operators

    @Test("Arithmetic operators")
    func testArithmeticOperators() throws {
        let tests: [(String, Token)] = [
            ("+", .plus),
            ("-", .minus),
            ("*", .star),
            ("/", .slash),
            ("%", .percent)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            #expect(tokens[0] == expected)
        }
    }

    @Test("Comparison operators")
    func testComparisonOperators() throws {
        let tests: [(String, Token)] = [
            ("==", .eq),
            ("!=", .neq),
            ("<", .lt),
            ("<=", .lte),
            (">", .gt),
            (">=", .gte)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            #expect(tokens[0] == expected)
        }
    }

    @Test("Logical operators")
    func testLogicalOperators() throws {
        let tests: [(String, Token)] = [
            ("&&", .and),
            ("||", .or),
            ("!", .not)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            #expect(tokens[0] == expected)
        }
    }

    // MARK: - Punctuation

    @Test("Punctuation")
    func testPunctuation() throws {
        let tests: [(String, Token)] = [
            (".", .dot),
            (",", .comma),
            (":", .colon),
            ("?", .questionMark),
            ("(", .lparen),
            (")", .rparen),
            ("[", .lbracket),
            ("]", .rbracket),
            ("{", .lbrace),
            ("}", .rbrace)
        ]

        for (input, expected) in tests {
            let lexer = Lexer(input: input)
            let tokens = try lexer.tokenize()
            #expect(tokens[0] == expected)
        }
    }

    // MARK: - Complex Expressions

    @Test("Simple expression")
    func testSimpleExpression() throws {
        let lexer = Lexer(input: "x + 1")
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 4) // x, +, 1, EOF
        guard case .identifier("x") = tokens[0] else {
            Issue.record("Expected identifier 'x'")
            return
        }
        #expect(tokens[1] == .plus)
        guard case .int(1) = tokens[2] else {
            Issue.record("Expected int 1")
            return
        }
        #expect(tokens[3] == .eof)
    }

    @Test("Member access expression")
    func testMemberAccessExpression() throws {
        let lexer = Lexer(input: "user.name")
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 4) // user, ., name, EOF
        guard case .identifier("user") = tokens[0] else {
            Issue.record("Expected identifier 'user'")
            return
        }
        #expect(tokens[1] == .dot)
        guard case .identifier("name") = tokens[2] else {
            Issue.record("Expected identifier 'name'")
            return
        }
    }

    @Test("Function call expression")
    func testFunctionCallExpression() throws {
        let lexer = Lexer(input: "size(list)")
        let tokens = try lexer.tokenize()

        guard case .identifier("size") = tokens[0] else {
            Issue.record("Expected identifier 'size'")
            return
        }
        #expect(tokens[1] == .lparen)
        guard case .identifier("list") = tokens[2] else {
            Issue.record("Expected identifier 'list'")
            return
        }
        #expect(tokens[3] == .rparen)
    }

    @Test("Whitespace handling")
    func testWhitespaceHandling() throws {
        let lexer = Lexer(input: "  x   +   1  ")
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 4) // Whitespace should be ignored
        guard case .identifier("x") = tokens[0] else {
            Issue.record("Expected identifier 'x'")
            return
        }
        #expect(tokens[1] == .plus)
        guard case .int(1) = tokens[2] else {
            Issue.record("Expected int 1")
            return
        }
    }

    // MARK: - Error Cases

    @Test("Invalid character")
    func testInvalidCharacter() throws {
        let lexer = Lexer(input: "@invalid")
        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Unterminated string")
    func testUnterminatedString() throws {
        let lexer = Lexer(input: "\"unterminated")
        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }
}
