import Testing
@testable import SwiftCEL

@Suite("Evaluator Tests")
struct EvaluatorTests {

    // MARK: - Literals

    @Test("Evaluate integer literal")
    func testIntegerLiteral() throws {
        let expr = try Parser.parse("42")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(42))
    }

    @Test("Evaluate string literal")
    func testStringLiteral() throws {
        let expr = try Parser.parse("\"hello\"")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .string("hello"))
    }

    @Test("Evaluate boolean literal")
    func testBooleanLiteral() throws {
        let expr = try Parser.parse("true")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    @Test("Evaluate null literal")
    func testNullLiteral() throws {
        let expr = try Parser.parse("null")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .null)
    }

    // MARK: - Identifiers

    @Test("Evaluate identifier")
    func testIdentifier() throws {
        let expr = try Parser.parse("x")
        let context = Context(bindings: ["x": .int(42)])
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(42))
    }

    @Test("Undefined identifier throws error")
    func testUndefinedIdentifier() throws {
        let expr = try Parser.parse("undefined")
        let context = Context()

        #expect(throws: EvalError.self) {
            try Evaluator().evaluate(expr, in: context)
        }
    }

    // MARK: - Arithmetic Operators

    @Test("Evaluate addition")
    func testAddition() throws {
        let expr = try Parser.parse("1 + 2")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(3))
    }

    @Test("Evaluate subtraction")
    func testSubtraction() throws {
        let expr = try Parser.parse("5 - 3")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(2))
    }

    @Test("Evaluate multiplication")
    func testMultiplication() throws {
        let expr = try Parser.parse("3 * 4")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(12))
    }

    @Test("Evaluate division")
    func testDivision() throws {
        let expr = try Parser.parse("10 / 2")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(5))
    }

    @Test("Evaluate modulo")
    func testModulo() throws {
        let expr = try Parser.parse("10 % 3")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(1))
    }

    // MARK: - Comparison Operators

    @Test("Evaluate equality")
    func testEquality() throws {
        let expr1 = try Parser.parse("5 == 5")
        let expr2 = try Parser.parse("5 == 3")
        let context = Context()

        #expect(try Evaluator().evaluate(expr1, in: context) == .bool(true))
        #expect(try Evaluator().evaluate(expr2, in: context) == .bool(false))
    }

    @Test("Evaluate inequality")
    func testInequality() throws {
        let expr1 = try Parser.parse("5 != 3")
        let expr2 = try Parser.parse("5 != 5")
        let context = Context()

        #expect(try Evaluator().evaluate(expr1, in: context) == .bool(true))
        #expect(try Evaluator().evaluate(expr2, in: context) == .bool(false))
    }

    @Test("Evaluate less than")
    func testLessThan() throws {
        let expr1 = try Parser.parse("3 < 5")
        let expr2 = try Parser.parse("5 < 3")
        let context = Context()

        #expect(try Evaluator().evaluate(expr1, in: context) == .bool(true))
        #expect(try Evaluator().evaluate(expr2, in: context) == .bool(false))
    }

    @Test("Evaluate greater than")
    func testGreaterThan() throws {
        let expr1 = try Parser.parse("5 > 3")
        let expr2 = try Parser.parse("3 > 5")
        let context = Context()

        #expect(try Evaluator().evaluate(expr1, in: context) == .bool(true))
        #expect(try Evaluator().evaluate(expr2, in: context) == .bool(false))
    }

    // MARK: - Logical Operators

    @Test("Evaluate logical AND")
    func testLogicalAnd() throws {
        let expr1 = try Parser.parse("true && true")
        let expr2 = try Parser.parse("true && false")
        let context = Context()

        #expect(try Evaluator().evaluate(expr1, in: context) == .bool(true))
        #expect(try Evaluator().evaluate(expr2, in: context) == .bool(false))
    }

    @Test("Evaluate logical OR")
    func testLogicalOr() throws {
        let expr1 = try Parser.parse("false || true")
        let expr2 = try Parser.parse("false || false")
        let context = Context()

        #expect(try Evaluator().evaluate(expr1, in: context) == .bool(true))
        #expect(try Evaluator().evaluate(expr2, in: context) == .bool(false))
    }

    @Test("Evaluate logical NOT")
    func testLogicalNot() throws {
        let expr1 = try Parser.parse("!true")
        let expr2 = try Parser.parse("!false")
        let context = Context()

        #expect(try Evaluator().evaluate(expr1, in: context) == .bool(false))
        #expect(try Evaluator().evaluate(expr2, in: context) == .bool(true))
    }

    // MARK: - Unary Operators

    @Test("Evaluate negation")
    func testNegation() throws {
        let expr = try Parser.parse("-5")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(-5))
    }

    // MARK: - Ternary Operator

    @Test("Evaluate ternary - true branch")
    func testTernaryTrue() throws {
        let expr = try Parser.parse("true ? 1 : 2")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(1))
    }

    @Test("Evaluate ternary - false branch")
    func testTernaryFalse() throws {
        let expr = try Parser.parse("false ? 1 : 2")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(2))
    }

    // MARK: - Lists

    @Test("Evaluate list literal")
    func testListLiteral() throws {
        let expr = try Parser.parse("[1, 2, 3]")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .list([.int(1), .int(2), .int(3)]))
    }

    @Test("Evaluate empty list")
    func testEmptyList() throws {
        let expr = try Parser.parse("[]")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .list([]))
    }

    // MARK: - Maps

    @Test("Evaluate map literal")
    func testMapLiteral() throws {
        let expr = try Parser.parse("{\"key\": \"value\"}")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        guard let map = result.asMap else {
            Issue.record("Expected map")
            return
        }

        #expect(map["key"] == .string("value"))
    }

    // MARK: - Complex Expressions

    @Test("Evaluate complex expression")
    func testComplexExpression() throws {
        let expr = try Parser.parse("(1 + 2) * 3")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(9))
    }

    @Test("Evaluate expression with variables")
    func testExpressionWithVariables() throws {
        let expr = try Parser.parse("x + y")
        let context = Context(bindings: [
            "x": .int(10),
            "y": .int(20)
        ])
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .int(30))
    }

    @Test("String concatenation")
    func testStringConcatenation() throws {
        let expr = try Parser.parse("\"hello\" + \" world\"")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .string("hello world"))
    }

    // MARK: - String Methods

    @Test("String contains() method")
    func testStringContains() throws {
        let expr1 = try Parser.parse("\"hello world\".contains(\"world\")")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .bool(true))

        let expr2 = try Parser.parse("\"hello world\".contains(\"xyz\")")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .bool(false))
    }

    @Test("String startsWith() method")
    func testStringStartsWith() throws {
        let expr1 = try Parser.parse("\"hello world\".startsWith(\"hello\")")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .bool(true))

        let expr2 = try Parser.parse("\"hello world\".startsWith(\"world\")")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .bool(false))
    }

    @Test("String endsWith() method")
    func testStringEndsWith() throws {
        let expr1 = try Parser.parse("\"hello world\".endsWith(\"world\")")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .bool(true))

        let expr2 = try Parser.parse("\"hello world\".endsWith(\"hello\")")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .bool(false))
    }

    @Test("String matches() method with regex")
    func testStringMatches() throws {
        let expr1 = try Parser.parse("\"john@gmail.com\".matches(\".*@gmail\\\\.com$\")")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .bool(true))

        let expr2 = try Parser.parse("\"john@yahoo.com\".matches(\".*@gmail\\\\.com$\")")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .bool(false))

        let expr3 = try Parser.parse("\"CA\".matches(\"^[A-Z]{2}$\")")
        let result3 = try Evaluator().evaluate(expr3, in: context)
        #expect(result3 == .bool(true))
    }

    @Test("String size() method")
    func testStringSize() throws {
        let expr1 = try Parser.parse("\"hello\".size()")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .int(5))

        let expr2 = try Parser.parse("\"\".size()")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .int(0))

        let expr3 = try Parser.parse("\"CA\".size()")
        let result3 = try Evaluator().evaluate(expr3, in: context)
        #expect(result3 == .int(2))
    }

    @Test("List size() method")
    func testListSize() throws {
        let expr1 = try Parser.parse("[1, 2, 3].size()")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .int(3))

        let expr2 = try Parser.parse("[].size()")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .int(0))
    }

    @Test("Map size() method")
    func testMapSize() throws {
        let expr1 = try Parser.parse("{\"a\": 1, \"b\": 2}.size()")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .int(2))

        let expr2 = try Parser.parse("{}.size()")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .int(0))
    }

    @Test("Global size() function")
    func testGlobalSize() throws {
        let expr1 = try Parser.parse("size(\"hello\")")
        let context = Context()
        let result1 = try Evaluator().evaluate(expr1, in: context)
        #expect(result1 == .int(5))

        let expr2 = try Parser.parse("size([1, 2, 3])")
        let result2 = try Evaluator().evaluate(expr2, in: context)
        #expect(result2 == .int(3))

        let expr3 = try Parser.parse("size({\"a\": 1})")
        let result3 = try Evaluator().evaluate(expr3, in: context)
        #expect(result3 == .int(1))
    }
}
