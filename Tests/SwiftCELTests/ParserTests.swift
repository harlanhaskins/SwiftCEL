import Testing
@testable import SwiftCEL

@Suite("Parser Tests")
struct ParserTests {

    // MARK: - Literals

    @Test("Parse integer literal")
    func testIntegerLiteral() throws {
        let expr = try Parser.parse("42")

        guard let lit = expr as? LiteralExpr else {
            Issue.record("Expected LiteralExpr")
            return
        }

        guard case .int(let value) = lit.value else {
            Issue.record("Expected int literal")
            return
        }

        #expect(value == 42)
    }

    @Test("Parse string literal")
    func testStringLiteral() throws {
        let expr = try Parser.parse("\"hello\"")

        guard let lit = expr as? LiteralExpr else {
            Issue.record("Expected LiteralExpr")
            return
        }

        guard case .string(let value) = lit.value else {
            Issue.record("Expected string literal")
            return
        }

        #expect(value == "hello")
    }

    @Test("Parse boolean literals")
    func testBooleanLiterals() throws {
        let trueExpr = try Parser.parse("true")
        guard let trueLit = trueExpr as? LiteralExpr,
              case .bool(let trueVal) = trueLit.value else {
            Issue.record("Expected true literal")
            return
        }
        #expect(trueVal == true)

        let falseExpr = try Parser.parse("false")
        guard let falseLit = falseExpr as? LiteralExpr,
              case .bool(let falseVal) = falseLit.value else {
            Issue.record("Expected false literal")
            return
        }
        #expect(falseVal == false)
    }

    // MARK: - Identifiers

    @Test("Parse identifier")
    func testIdentifier() throws {
        let expr = try Parser.parse("name")

        guard let ident = expr as? IdentExpr else {
            Issue.record("Expected IdentExpr")
            return
        }

        #expect(ident.name == "name")
    }

    // MARK: - Binary Operators

    @Test("Parse addition")
    func testAddition() throws {
        let expr = try Parser.parse("1 + 2")

        guard let binary = expr as? BinaryExpr else {
            Issue.record("Expected BinaryExpr")
            return
        }

        #expect(binary.op == .add)

        guard let lhs = binary.lhs as? LiteralExpr,
              case .int(1) = lhs.value else {
            Issue.record("Expected left operand to be 1")
            return
        }

        guard let rhs = binary.rhs as? LiteralExpr,
              case .int(2) = rhs.value else {
            Issue.record("Expected right operand to be 2")
            return
        }
    }

    @Test("Parse multiplication with higher precedence")
    func testOperatorPrecedence() throws {
        // 1 + 2 * 3 should parse as 1 + (2 * 3)
        let expr = try Parser.parse("1 + 2 * 3")

        guard let add = expr as? BinaryExpr else {
            Issue.record("Expected BinaryExpr for addition")
            return
        }

        #expect(add.op == .add)

        // Left should be 1
        guard let lhs = add.lhs as? LiteralExpr,
              case .int(1) = lhs.value else {
            Issue.record("Expected left operand to be 1")
            return
        }

        // Right should be 2 * 3
        guard let mult = add.rhs as? BinaryExpr else {
            Issue.record("Expected BinaryExpr for multiplication")
            return
        }

        #expect(mult.op == .multiply)
    }

    @Test("Parse comparison")
    func testComparison() throws {
        let expr = try Parser.parse("x == 5")

        guard let binary = expr as? BinaryExpr else {
            Issue.record("Expected BinaryExpr")
            return
        }

        #expect(binary.op == .equal)

        guard let lhs = binary.lhs as? IdentExpr else {
            Issue.record("Expected IdentExpr")
            return
        }
        #expect(lhs.name == "x")

        guard let rhs = binary.rhs as? LiteralExpr,
              case .int(5) = rhs.value else {
            Issue.record("Expected int 5")
            return
        }
    }

    @Test("Parse logical AND")
    func testLogicalAnd() throws {
        let expr = try Parser.parse("true && false")

        guard let binary = expr as? BinaryExpr else {
            Issue.record("Expected BinaryExpr")
            return
        }

        #expect(binary.op == .and)
    }

    @Test("Parse logical OR")
    func testLogicalOr() throws {
        let expr = try Parser.parse("true || false")

        guard let binary = expr as? BinaryExpr else {
            Issue.record("Expected BinaryExpr")
            return
        }

        #expect(binary.op == .or)
    }

    // MARK: - Unary Operators

    @Test("Parse negation")
    func testNegation() throws {
        let expr = try Parser.parse("-5")

        guard let unary = expr as? UnaryExpr else {
            Issue.record("Expected UnaryExpr")
            return
        }

        #expect(unary.op == .negate)

        guard let operand = unary.operand as? LiteralExpr,
              case .int(5) = operand.value else {
            Issue.record("Expected int 5")
            return
        }
    }

    @Test("Parse logical NOT")
    func testLogicalNot() throws {
        let expr = try Parser.parse("!true")

        guard let unary = expr as? UnaryExpr else {
            Issue.record("Expected UnaryExpr")
            return
        }

        #expect(unary.op == .not)
    }

    // MARK: - Member Access

    @Test("Parse member access")
    func testMemberAccess() throws {
        let expr = try Parser.parse("user.name")

        guard let select = expr as? SelectExpr else {
            Issue.record("Expected SelectExpr")
            return
        }

        #expect(select.field == "name")

        guard let operand = select.operand as? IdentExpr else {
            Issue.record("Expected IdentExpr")
            return
        }

        #expect(operand.name == "user")
    }

    @Test("Parse chained member access")
    func testChainedMemberAccess() throws {
        let expr = try Parser.parse("user.address.city")

        guard let select1 = expr as? SelectExpr else {
            Issue.record("Expected SelectExpr")
            return
        }

        #expect(select1.field == "city")

        guard let select2 = select1.operand as? SelectExpr else {
            Issue.record("Expected SelectExpr")
            return
        }

        #expect(select2.field == "address")

        guard let ident = select2.operand as? IdentExpr else {
            Issue.record("Expected IdentExpr")
            return
        }

        #expect(ident.name == "user")
    }

    // MARK: - Function Calls

    @Test("Parse function call")
    func testFunctionCall() throws {
        let expr = try Parser.parse("size(list)")

        guard let call = expr as? CallExpr else {
            Issue.record("Expected CallExpr")
            return
        }

        #expect(call.function == "size")
        #expect(call.args.count == 1)

        guard let arg = call.args[0] as? IdentExpr else {
            Issue.record("Expected IdentExpr argument")
            return
        }

        #expect(arg.name == "list")
    }

    @Test("Parse function call with multiple arguments")
    func testMultipleArguments() throws {
        let expr = try Parser.parse("func(a, b, c)")

        guard let call = expr as? CallExpr else {
            Issue.record("Expected CallExpr")
            return
        }

        #expect(call.function == "func")
        #expect(call.args.count == 3)
    }

    @Test("Parse member call")
    func testMemberCall() throws {
        let expr = try Parser.parse("str.startsWith(\"hello\")")

        guard let memberCall = expr as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr")
            return
        }

        #expect(memberCall.method == "startsWith")
        #expect(memberCall.args.count == 1)

        guard let operand = memberCall.operand as? IdentExpr else {
            Issue.record("Expected IdentExpr")
            return
        }

        #expect(operand.name == "str")
    }

    // MARK: - Ternary Operator

    @Test("Parse ternary operator")
    func testTernary() throws {
        let expr = try Parser.parse("x > 0 ? 1 : -1")

        guard let ternary = expr as? TernaryExpr else {
            Issue.record("Expected TernaryExpr")
            return
        }

        // Condition should be x > 0
        guard let cond = ternary.condition as? BinaryExpr else {
            Issue.record("Expected BinaryExpr for condition")
            return
        }

        #expect(cond.op == .greaterThan)

        // True expression should be 1
        guard let trueExpr = ternary.trueExpr as? LiteralExpr,
              case .int(1) = trueExpr.value else {
            Issue.record("Expected int 1 for true branch")
            return
        }

        // False expression should be -1
        guard let falseExpr = ternary.falseExpr as? UnaryExpr else {
            Issue.record("Expected UnaryExpr for false branch")
            return
        }

        #expect(falseExpr.op == .negate)
    }

    // MARK: - Collections

    @Test("Parse list literal")
    func testListLiteral() throws {
        let expr = try Parser.parse("[1, 2, 3]")

        guard let list = expr as? ListExpr else {
            Issue.record("Expected ListExpr")
            return
        }

        #expect(list.elements.count == 3)
    }

    @Test("Parse empty list")
    func testEmptyList() throws {
        let expr = try Parser.parse("[]")

        guard let list = expr as? ListExpr else {
            Issue.record("Expected ListExpr")
            return
        }

        #expect(list.elements.count == 0)
    }

    @Test("Parse map literal")
    func testMapLiteral() throws {
        let expr = try Parser.parse("{\"key\": \"value\"}")

        guard let map = expr as? MapExpr else {
            Issue.record("Expected MapExpr")
            return
        }

        #expect(map.entries.count == 1)
    }

    // MARK: - Complex Expressions

    @Test("Parse complex expression")
    func testComplexExpression() throws {
        // name.startsWith("John") && age > 18
        let expr = try Parser.parse("name.startsWith(\"John\") && age > 18")

        guard let and = expr as? BinaryExpr else {
            Issue.record("Expected BinaryExpr for AND")
            return
        }

        #expect(and.op == .and)

        // Left: name.startsWith("John")
        guard let lhs = and.lhs as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr")
            return
        }

        #expect(lhs.method == "startsWith")

        // Right: age > 18
        guard let rhs = and.rhs as? BinaryExpr else {
            Issue.record("Expected BinaryExpr")
            return
        }

        #expect(rhs.op == .greaterThan)
    }

    // MARK: - Macros

    @Test("Parse exists macro")
    func testExistsMacro() throws {
        let expr = try Parser.parse("emails.exists(e, e.endsWith(\"@example.com\"))")

        guard let memberCall = expr as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr")
            return
        }

        #expect(memberCall.method == "exists")
        #expect(memberCall.args.count == 2)

        guard let varArg = memberCall.args[0] as? IdentExpr else {
            Issue.record("Expected IdentExpr for variable argument")
            return
        }

        #expect(varArg.name == "e")

        guard let target = memberCall.operand as? IdentExpr else {
            Issue.record("Expected IdentExpr for target")
            return
        }

        #expect(target.name == "emails")
    }

    @Test("Parse all macro")
    func testAllMacro() throws {
        let expr = try Parser.parse("numbers.all(n, n > 0)")

        guard let memberCall = expr as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr")
            return
        }

        #expect(memberCall.method == "all")
        #expect(memberCall.args.count == 2)

        guard let varArg = memberCall.args[0] as? IdentExpr else {
            Issue.record("Expected IdentExpr for variable argument")
            return
        }

        #expect(varArg.name == "n")
    }

    // MARK: - Parentheses

    @Test("Parse parenthesized expression")
    func testParentheses() throws {
        // (1 + 2) * 3 should parse with addition grouped
        let expr = try Parser.parse("(1 + 2) * 3")

        guard let mult = expr as? BinaryExpr else {
            Issue.record("Expected BinaryExpr for multiplication")
            return
        }

        #expect(mult.op == .multiply)

        // Left should be (1 + 2)
        guard let add = mult.lhs as? BinaryExpr else {
            Issue.record("Expected BinaryExpr for addition")
            return
        }

        #expect(add.op == .add)
    }
}
