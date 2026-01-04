import Testing
@testable import SwiftCEL

@Suite("Macro Tests")
struct MacroTests {

    // MARK: - exists() macro

    @Test("exists() returns true when predicate matches")
    func testExistsTrue() throws {
        let expr = try Parser.parse("[1, 2, 3].exists(x, x > 2)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    @Test("exists() returns false when no match")
    func testExistsFalse() throws {
        let expr = try Parser.parse("[1, 2, 3].exists(x, x > 10)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(false))
    }

    @Test("exists() with empty list returns false")
    func testExistsEmpty() throws {
        let expr = try Parser.parse("[].exists(x, x > 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(false))
    }

    @Test("exists() with complex predicate")
    func testExistsComplex() throws {
        let expr = try Parser.parse("[\"apple\", \"banana\", \"cherry\"].exists(s, s == \"banana\")")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    // MARK: - all() macro

    @Test("all() returns true when all match")
    func testAllTrue() throws {
        let expr = try Parser.parse("[1, 2, 3].all(x, x > 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    @Test("all() returns false when not all match")
    func testAllFalse() throws {
        let expr = try Parser.parse("[1, 2, 3].all(x, x > 2)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(false))
    }

    @Test("all() with empty list returns true")
    func testAllEmpty() throws {
        let expr = try Parser.parse("[].all(x, x > 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    @Test("all() with complex predicate")
    func testAllComplex() throws {
        let expr = try Parser.parse("[2, 4, 6].all(x, x % 2 == 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    // MARK: - exists_one() macro

    @Test("exists_one() returns true when exactly one matches")
    func testExistsOneTrue() throws {
        let expr = try Parser.parse("[1, 2, 3].exists_one(x, x == 2)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    @Test("exists_one() returns false when zero match")
    func testExistsOneZero() throws {
        let expr = try Parser.parse("[1, 2, 3].exists_one(x, x > 10)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(false))
    }

    @Test("exists_one() returns false when multiple match")
    func testExistsOneMultiple() throws {
        let expr = try Parser.parse("[1, 2, 3].exists_one(x, x > 1)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(false))
    }

    @Test("exists_one() with empty list returns false")
    func testExistsOneEmpty() throws {
        let expr = try Parser.parse("[].exists_one(x, x > 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(false))
    }

    // MARK: - filter() macro

    @Test("filter() returns matching elements")
    func testFilter() throws {
        let expr = try Parser.parse("[1, 2, 3, 4, 5].filter(x, x > 2)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .list([.int(3), .int(4), .int(5)]))
    }

    @Test("filter() with no matches returns empty list")
    func testFilterNoMatches() throws {
        let expr = try Parser.parse("[1, 2, 3].filter(x, x > 10)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .list([]))
    }

    @Test("filter() with all matches returns all elements")
    func testFilterAllMatches() throws {
        let expr = try Parser.parse("[1, 2, 3].filter(x, x > 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .list([.int(1), .int(2), .int(3)]))
    }

    @Test("filter() with empty list returns empty list")
    func testFilterEmpty() throws {
        let expr = try Parser.parse("[].filter(x, x > 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .list([]))
    }

    @Test("filter() with complex predicate")
    func testFilterComplex() throws {
        let expr = try Parser.parse("[1, 2, 3, 4, 5, 6].filter(x, x % 2 == 0)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .list([.int(2), .int(4), .int(6)]))
    }

    // MARK: - Nested macros

    @Test("Nested macros")
    func testNestedMacros() throws {
        // [[1,2], [3,4], [5,6]].exists(list, list.exists(x, x > 5))
        let expr = try Parser.parse("[[1,2], [3,4], [5,6]].exists(list, list.exists(x, x > 5))")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    @Test("filter then exists")
    func testFilterThenExists() throws {
        // [1,2,3,4,5].filter(x, x > 2).exists(y, y == 4)
        let expr = try Parser.parse("[1,2,3,4,5].filter(x, x > 2).exists(y, y == 4)")
        let context = Context()
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    // MARK: - Macros with context variables

    @Test("Macro accessing context variable")
    func testMacroWithContext() throws {
        let expr = try Parser.parse("[1, 2, 3].exists(x, x > threshold)")
        let context = Context(bindings: ["threshold": .int(2)])
        let result = try Evaluator().evaluate(expr, in: context)

        #expect(result == .bool(true))
    }

    @Test("Macro variable shadows context variable")
    func testMacroShadowing() throws {
        let expr = try Parser.parse("[1, 2, 3].exists(x, x == x)")
        let context = Context(bindings: ["x": .int(100)])
        let result = try Evaluator().evaluate(expr, in: context)

        // The macro variable 'x' shadows the context variable 'x'
        // x == x should always be true for each element
        #expect(result == .bool(true))
    }
}
