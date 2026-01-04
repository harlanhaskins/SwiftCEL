import Testing
@testable import SwiftCEL

@Suite("Function Registry Tests")
struct FunctionRegistryTests {

    // MARK: - Custom Global Functions

    @Test("Register and call custom global function")
    func testCustomGlobalFunction() throws {
        var registry = FunctionRegistry()

        // Register a custom double() function
        registry.registerGlobalFunction(name: "double", parameters: [
            ParameterDefinition(name: "value", type: .int)
        ]) { args in
            let num = args[0].asInt!
            return .int(num * 2)
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("double(5)")
        let context = Context()
        let result = try evaluator.evaluate(expr, in: context)

        #expect(result == .int(10))
    }

    @Test("Custom function with multiple parameters")
    func testCustomFunctionMultipleParams() throws {
        var registry = FunctionRegistry()

        // Register an add() function
        registry.registerGlobalFunction(name: "add", parameters: [
            ParameterDefinition(name: "a", type: .int),
            ParameterDefinition(name: "b", type: .int)
        ]) { args in
            let a = args[0].asInt!
            let b = args[1].asInt!
            return .int(a + b)
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("add(3, 7)")
        let context = Context()
        let result = try evaluator.evaluate(expr, in: context)

        #expect(result == .int(10))
    }

    @Test("Custom function with .any parameter type")
    func testCustomFunctionAnyType() throws {
        var registry = FunctionRegistry()

        // Register a typeof() function that works with any value
        registry.registerGlobalFunction(name: "typeof", parameters: [
            ParameterDefinition(name: "value", type: .any)
        ]) { args in
            let value = args[0]
            switch value {
            case .string: return .string("string")
            case .int: return .string("int")
            case .bool: return .string("bool")
            case .list: return .string("list")
            case .map: return .string("map")
            default: return .string("unknown")
            }
        }

        let evaluator = Evaluator(registry: registry)

        // Test with different types
        let expr1 = try Parser.parse("typeof(\"hello\")")
        let result1 = try evaluator.evaluate(expr1, in: Context())
        #expect(result1 == .string("string"))

        let expr2 = try Parser.parse("typeof(42)")
        let result2 = try evaluator.evaluate(expr2, in: Context())
        #expect(result2 == .string("int"))

        let expr3 = try Parser.parse("typeof([1, 2, 3])")
        let result3 = try evaluator.evaluate(expr3, in: Context())
        #expect(result3 == .string("list"))
    }

    // MARK: - Custom Methods

    @Test("Register and call custom string method")
    func testCustomStringMethod() throws {
        var registry = FunctionRegistry()

        // Register a reverse() method for strings
        registry.registerMethod(type: .string, methodName: "reverse", parameters: [
            ParameterDefinition(name: "self", type: .string)
        ]) { args in
            let str = args[0].asString!
            return .string(String(str.reversed()))
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("\"hello\".reverse()")
        let context = Context()
        let result = try evaluator.evaluate(expr, in: context)

        #expect(result == .string("olleh"))
    }

    @Test("Custom method with parameters")
    func testCustomMethodWithParams() throws {
        var registry = FunctionRegistry()

        // Register a repeat() method for strings
        registry.registerMethod(type: .string, methodName: "repeat", parameters: [
            ParameterDefinition(name: "self", type: .string),
            ParameterDefinition(name: "times", type: .int)
        ]) { args in
            let str = args[0].asString!
            let times = args[1].asInt!
            return .string(String(repeating: str, count: Int(times)))
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("\"ab\".repeat(3)")
        let context = Context()
        let result = try evaluator.evaluate(expr, in: context)

        #expect(result == .string("ababab"))
    }

    @Test("Custom list method")
    func testCustomListMethod() throws {
        var registry = FunctionRegistry()

        // Register a first() method for lists
        registry.registerMethod(type: .list, methodName: "first", parameters: [
            ParameterDefinition(name: "self", type: .list)
        ]) { args in
            let list = args[0].asList!
            guard !list.isEmpty else {
                return .null
            }
            return list[0]
        }

        let evaluator = Evaluator(registry: registry)

        // Test with non-empty list
        let expr1 = try Parser.parse("[1, 2, 3].first()")
        let result1 = try evaluator.evaluate(expr1, in: Context())
        #expect(result1 == .int(1))

        // Test with empty list
        let expr2 = try Parser.parse("[].first()")
        let result2 = try evaluator.evaluate(expr2, in: Context())
        #expect(result2 == .null)
    }

    // MARK: - Parameter Validation

    @Test("Function rejects wrong argument count")
    func testArgumentCountValidation() throws {
        var registry = FunctionRegistry()

        registry.registerGlobalFunction(name: "square", parameters: [
            ParameterDefinition(name: "value", type: .int)
        ]) { args in
            let num = args[0].asInt!
            return .int(num * num)
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("square(2, 3)")  // Wrong: 2 args instead of 1
        let context = Context()

        #expect(throws: EvalError.self) {
            try evaluator.evaluate(expr, in: context)
        }
    }

    @Test("Function rejects wrong argument type")
    func testArgumentTypeValidation() throws {
        var registry = FunctionRegistry()

        registry.registerGlobalFunction(name: "square", parameters: [
            ParameterDefinition(name: "value", type: .int)
        ]) { args in
            let num = args[0].asInt!
            return .int(num * num)
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("square(\"hello\")")  // Wrong: string instead of int
        let context = Context()

        #expect(throws: EvalError.self) {
            try evaluator.evaluate(expr, in: context)
        }
    }

    @Test("Method rejects wrong receiver type")
    func testMethodReceiverValidation() throws {
        var registry = FunctionRegistry()

        // Register reverse() only for strings
        registry.registerMethod(type: .string, methodName: "reverse", parameters: [
            ParameterDefinition(name: "self", type: .string)
        ]) { args in
            let str = args[0].asString!
            return .string(String(str.reversed()))
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("42.reverse()")  // Wrong: int instead of string
        let context = Context()

        #expect(throws: EvalError.self) {
            try evaluator.evaluate(expr, in: context)
        }
    }

    // MARK: - Integration with Standard Library

    @Test("Custom functions work alongside standard library")
    func testCustomWithStandardLibrary() throws {
        var registry = FunctionRegistry()

        // Add custom function
        registry.registerGlobalFunction(name: "triple", parameters: [
            ParameterDefinition(name: "value", type: .int)
        ]) { args in
            let num = args[0].asInt!
            return .int(num * 3)
        }

        let evaluator = Evaluator(registry: registry)

        // Use both custom and standard library functions
        let expr = try Parser.parse("size(\"hello\") + triple(2)")
        let context = Context()
        let result = try evaluator.evaluate(expr, in: context)

        #expect(result == .int(11))  // 5 + 6
    }

    @Test("Override standard library function")
    func testOverrideStandardFunction() throws {
        var registry = FunctionRegistry()

        // Override size() to always return 42
        registry.registerGlobalFunction(name: "size", parameters: [
            ParameterDefinition(name: "value", type: .any)
        ]) { args in
            return .int(42)
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("size(\"hello\")")
        let context = Context()
        let result = try evaluator.evaluate(expr, in: context)

        #expect(result == .int(42))  // Custom implementation, not 5
    }

    // MARK: - Complex Custom Functions

    @Test("Custom function that throws errors")
    func testCustomFunctionWithErrors() throws {
        var registry = FunctionRegistry()

        // Register a divide() function that validates non-zero divisor
        registry.registerGlobalFunction(name: "safeDivide", parameters: [
            ParameterDefinition(name: "a", type: .int),
            ParameterDefinition(name: "b", type: .int)
        ]) { args in
            let a = args[0].asInt!
            let b = args[1].asInt!

            guard b != 0 else {
                throw EvalError.divisionByZero
            }

            return .int(a / b)
        }

        let evaluator = Evaluator(registry: registry)

        // Test success case
        let expr1 = try Parser.parse("safeDivide(10, 2)")
        let result1 = try evaluator.evaluate(expr1, in: Context())
        #expect(result1 == .int(5))

        // Test error case
        let expr2 = try Parser.parse("safeDivide(10, 0)")
        #expect(throws: EvalError.self) {
            try evaluator.evaluate(expr2, in: Context())
        }
    }

    @Test("Custom function that accesses context")
    func testCustomFunctionContextAccess() throws {
        var registry = FunctionRegistry()

        // Register a function that creates lists
        registry.registerGlobalFunction(name: "range", parameters: [
            ParameterDefinition(name: "end", type: .int)
        ]) { args in
            let end = args[0].asInt!
            let values = (0..<end).map { Value.int(Int64($0)) }
            return .list(Array(values))
        }

        let evaluator = Evaluator(registry: registry)
        let expr = try Parser.parse("range(3)")
        let context = Context()
        let result = try evaluator.evaluate(expr, in: context)

        #expect(result == .list([.int(0), .int(1), .int(2)]))
    }
}
