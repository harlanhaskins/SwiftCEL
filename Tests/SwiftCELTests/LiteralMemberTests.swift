import Testing
@testable import SwiftCEL

@Suite("Literal Member Expression Tests")
struct LiteralMemberTests {

    @Test("Parse string literal with method call")
    func testStringLiteralMethodCall() throws {
        let expr = try Parser.parse("\"hello\".size()")

        guard let memberCall = expr as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr, got \(type(of: expr))")
            return
        }

        #expect(memberCall.method == "size")

        guard let operand = memberCall.operand as? LiteralExpr else {
            Issue.record("Expected LiteralExpr operand, got \(type(of: memberCall.operand))")
            return
        }

        guard case .string(let value) = operand.value else {
            Issue.record("Expected string literal")
            return
        }

        #expect(value == "hello")
    }

    @Test("Parse list literal with method call")
    func testListLiteralMethodCall() throws {
        let expr = try Parser.parse("[1, 2, 3].size()")

        guard let memberCall = expr as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr, got \(type(of: expr))")
            return
        }

        #expect(memberCall.method == "size")

        guard let operand = memberCall.operand as? ListExpr else {
            Issue.record("Expected ListExpr operand, got \(type(of: memberCall.operand))")
            return
        }

        #expect(operand.elements.count == 3)
    }

    @Test("Parse map literal with member access")
    func testMapLiteralMemberAccess() throws {
        let expr = try Parser.parse("{\"key\": \"value\"}.key")

        guard let select = expr as? SelectExpr else {
            Issue.record("Expected SelectExpr, got \(type(of: expr))")
            return
        }

        #expect(select.field == "key")

        guard let operand = select.operand as? MapExpr else {
            Issue.record("Expected MapExpr operand, got \(type(of: select.operand))")
            return
        }

        #expect(operand.entries.count == 1)
    }

    @Test("Parse parenthesized expression with method call")
    func testParenthesizedExpressionMethodCall() throws {
        let expr = try Parser.parse("(1 + 2).toString()")

        guard let memberCall = expr as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr, got \(type(of: expr))")
            return
        }

        #expect(memberCall.method == "toString")

        guard let operand = memberCall.operand as? BinaryExpr else {
            Issue.record("Expected BinaryExpr operand, got \(type(of: memberCall.operand))")
            return
        }

        #expect(operand.op == .add)
    }

    @Test("Parse chained method calls on literal")
    func testChainedMethodCallsOnLiteral() throws {
        let expr = try Parser.parse("\"hello\".toUpper().size()")

        guard let outerCall = expr as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr, got \(type(of: expr))")
            return
        }

        #expect(outerCall.method == "size")

        guard let innerCall = outerCall.operand as? MemberCallExpr else {
            Issue.record("Expected MemberCallExpr operand, got \(type(of: outerCall.operand))")
            return
        }

        #expect(innerCall.method == "toUpper")

        guard let literal = innerCall.operand as? LiteralExpr else {
            Issue.record("Expected LiteralExpr, got \(type(of: innerCall.operand))")
            return
        }

        guard case .string("hello") = literal.value else {
            Issue.record("Expected string literal 'hello'")
            return
        }
    }
}
