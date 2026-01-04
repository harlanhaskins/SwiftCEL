import Foundation

// MARK: - Evaluation Error

public enum EvalError: Error, CustomStringConvertible {
    case undefinedVariable(String)
    case typeMismatch(String)
    case divisionByZero
    case invalidOperation(String)
    case undefinedFunction(String)

    public var description: String {
        switch self {
        case .undefinedVariable(let name):
            return "Undefined variable: \(name)"
        case .typeMismatch(let msg):
            return "Type mismatch: \(msg)"
        case .divisionByZero:
            return "Division by zero"
        case .invalidOperation(let msg):
            return "Invalid operation: \(msg)"
        case .undefinedFunction(let name):
            return "Undefined function: \(name)"
        }
    }
}

// MARK: - Evaluator

public struct Evaluator {
    public let registry: FunctionRegistry

    public init(registry: FunctionRegistry = FunctionRegistry()) {
        self.registry = registry
    }

    /// Evaluate a textual query in a given context
    public func evaluate(_ query: String, in context: Context) throws -> Value {
        let expr = try Parser.parse(query)
        return try evaluate(expr, in: context)
    }

    /// Evaluate an expression in a given context
    public func evaluate(_ expr: any Expr, in context: Context) throws -> Value {
        switch expr {
        case let e as LiteralExpr:
            return try evalLiteral(e, context: context)
        case let e as IdentExpr:
            return try evalIdent(e, context: context)
        case let e as UnaryExpr:
            return try evalUnary(e, context: context)
        case let e as BinaryExpr:
            return try evalBinary(e, context: context)
        case let e as TernaryExpr:
            return try evalTernary(e, context: context)
        case let e as SelectExpr:
            return try evalSelect(e, context: context)
        case let e as IndexExpr:
            return try evalIndex(e, context: context)
        case let e as CallExpr:
            return try evalCall(e, context: context)
        case let e as MemberCallExpr:
            return try evalMemberCall(e, context: context)
        case let e as ListExpr:
            return try evalList(e, context: context)
        case let e as MapExpr:
            return try evalMap(e, context: context)
        default:
            throw EvalError.invalidOperation("Unknown expression type")
        }
    }

    // MARK: - Literal Evaluation

    private func evalLiteral(_ expr: LiteralExpr, context: Context) throws -> Value {
        switch expr.value {
        case .int(let v): return .int(v)
        case .uint(let v): return .uint(v)
        case .double(let v): return .double(v)
        case .string(let v): return .string(v)
        case .bytes(let v): return .bytes(v)
        case .bool(let v): return .bool(v)
        case .null: return .null
        }
    }

    // MARK: - Identifier Evaluation

    private func evalIdent(_ expr: IdentExpr, context: Context) throws -> Value {
        guard let value = context.get(expr.name) else {
            throw EvalError.undefinedVariable(expr.name)
        }
        return value
    }

    // MARK: - Unary Operator Evaluation

    private func evalUnary(_ expr: UnaryExpr, context: Context) throws -> Value {
        let operand = try evaluate(expr.operand, in: context)

        switch expr.op {
        case .not:
            guard let b = operand.asBool else {
                throw EvalError.typeMismatch("! requires boolean operand")
            }
            return .bool(!b)

        case .negate:
            if let i = operand.asInt {
                return .int(-i)
            } else if let d = operand.asDouble {
                return .double(-d)
            } else {
                throw EvalError.typeMismatch("- requires numeric operand")
            }
        }
    }

    // MARK: - Binary Operator Evaluation

    private func evalBinary(_ expr: BinaryExpr, context: Context) throws -> Value {
        let lhs = try evaluate(expr.lhs, in: context)
        let rhs = try evaluate(expr.rhs, in: context)

        switch expr.op {
        // Arithmetic
        case .add:
            return try evalAdd(lhs, rhs)
        case .subtract:
            return try evalSubtract(lhs, rhs)
        case .multiply:
            return try evalMultiply(lhs, rhs)
        case .divide:
            return try evalDivide(lhs, rhs)
        case .modulo:
            return try evalModulo(lhs, rhs)

        // Comparison
        case .equal:
            return .bool(lhs == rhs)
        case .notEqual:
            return .bool(lhs != rhs)
        case .lessThan:
            return try evalLessThan(lhs, rhs)
        case .lessThanOrEqual:
            return try evalLessThanOrEqual(lhs, rhs)
        case .greaterThan:
            return try evalGreaterThan(lhs, rhs)
        case .greaterThanOrEqual:
            return try evalGreaterThanOrEqual(lhs, rhs)

        // Logical
        case .and:
            guard let l = lhs.asBool, let r = rhs.asBool else {
                throw EvalError.typeMismatch("&& requires boolean operands")
            }
            return .bool(l && r)
        case .or:
            guard let l = lhs.asBool, let r = rhs.asBool else {
                throw EvalError.typeMismatch("|| requires boolean operands")
            }
            return .bool(l || r)

        // Membership
        case .in:
            return try evalIn(lhs, rhs)
        }
    }

    // MARK: - Arithmetic Helpers

    private func evalAdd(_ lhs: Value, _ rhs: Value) throws -> Value {
        // String concatenation
        if let l = lhs.asString, let r = rhs.asString {
            return .string(l + r)
        }

        // Numeric addition
        if let l = lhs.asInt, let r = rhs.asInt {
            return .int(l + r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            return .double(l + r)
        }
        if let l = lhs.asInt, let r = rhs.asDouble {
            return .double(Double(l) + r)
        }
        if let l = lhs.asDouble, let r = rhs.asInt {
            return .double(l + Double(r))
        }

        throw EvalError.typeMismatch("+ requires numeric or string operands")
    }

    private func evalSubtract(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            return .int(l - r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            return .double(l - r)
        }
        throw EvalError.typeMismatch("- requires numeric operands")
    }

    private func evalMultiply(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            return .int(l * r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            return .double(l * r)
        }
        throw EvalError.typeMismatch("* requires numeric operands")
    }

    private func evalDivide(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            guard r != 0 else { throw EvalError.divisionByZero }
            return .int(l / r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            guard r != 0.0 else { throw EvalError.divisionByZero }
            return .double(l / r)
        }
        throw EvalError.typeMismatch("/ requires numeric operands")
    }

    private func evalModulo(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            guard r != 0 else { throw EvalError.divisionByZero }
            return .int(l % r)
        }
        throw EvalError.typeMismatch("% requires integer operands")
    }

    // MARK: - Comparison Helpers

    private func evalLessThan(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            return .bool(l < r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            return .bool(l < r)
        }
        if let l = lhs.asString, let r = rhs.asString {
            return .bool(l < r)
        }
        throw EvalError.typeMismatch("< requires comparable operands")
    }

    private func evalLessThanOrEqual(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            return .bool(l <= r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            return .bool(l <= r)
        }
        if let l = lhs.asString, let r = rhs.asString {
            return .bool(l <= r)
        }
        throw EvalError.typeMismatch("<= requires comparable operands")
    }

    private func evalGreaterThan(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            return .bool(l > r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            return .bool(l > r)
        }
        if let l = lhs.asString, let r = rhs.asString {
            return .bool(l > r)
        }
        throw EvalError.typeMismatch("> requires comparable operands")
    }

    private func evalGreaterThanOrEqual(_ lhs: Value, _ rhs: Value) throws -> Value {
        if let l = lhs.asInt, let r = rhs.asInt {
            return .bool(l >= r)
        }
        if let l = lhs.asDouble, let r = rhs.asDouble {
            return .bool(l >= r)
        }
        if let l = lhs.asString, let r = rhs.asString {
            return .bool(l >= r)
        }
        throw EvalError.typeMismatch(">= requires comparable operands")
    }

    private func evalIn(_ lhs: Value, _ rhs: Value) throws -> Value {
        // Check if lhs is in rhs list
        if let list = rhs.asList {
            return .bool(list.contains(lhs))
        }

        // Check if lhs is a key in rhs map
        if let key = lhs.asString, let map = rhs.asMap {
            return .bool(map[key] != nil)
        }

        throw EvalError.typeMismatch("in requires list or map")
    }

    // MARK: - Ternary Evaluation

    private func evalTernary(_ expr: TernaryExpr, context: Context) throws -> Value {
        let condition = try evaluate(expr.condition, in: context)

        guard let isTrue = condition.asBool else {
            throw EvalError.typeMismatch("Ternary condition must be boolean")
        }

        if isTrue {
            return try evaluate(expr.trueExpr, in: context)
        } else {
            return try evaluate(expr.falseExpr, in: context)
        }
    }

    // MARK: - Member Access Evaluation

    private func evalSelect(_ expr: SelectExpr, context: Context) throws -> Value {
        let operand = try evaluate(expr.operand, in: context)

        guard let map = operand.asMap else {
            throw EvalError.typeMismatch("Member access requires map")
        }

        guard let value = map[expr.field] else {
            return .null
        }

        return value
    }

    private func evalIndex(_ expr: IndexExpr, context: Context) throws -> Value {
        let operand = try evaluate(expr.operand, in: context)
        let index = try evaluate(expr.index, in: context)

        // List indexing
        if let list = operand.asList {
            guard let i = index.asInt else {
                throw EvalError.typeMismatch("List index must be integer")
            }
            guard i >= 0 && i < list.count else {
                return .null
            }
            return list[Int(i)]
        }

        // Map indexing
        if let map = operand.asMap {
            guard let key = index.asString else {
                throw EvalError.typeMismatch("Map index must be string")
            }
            return map[key] ?? .null
        }

        throw EvalError.typeMismatch("Index requires list or map")
    }

    // MARK: - List and Map Evaluation

    private func evalList(_ expr: ListExpr, context: Context) throws -> Value {
        let elements = try expr.elements.map { try evaluate($0, in: context) }
        return .list(elements)
    }

    private func evalMap(_ expr: MapExpr, context: Context) throws -> Value {
        var map: [String: Value] = [:]

        for (keyExpr, valueExpr) in expr.entries {
            let key = try evaluate(keyExpr, in: context)
            guard let keyString = key.asString else {
                throw EvalError.typeMismatch("Map key must be string")
            }

            let value = try evaluate(valueExpr, in: context)
            map[keyString] = value
        }

        return .map(map)
    }

    // MARK: - Function Call Evaluation

    private func evalCall(_ expr: CallExpr, context: Context) throws -> Value {
        // Look up global function in registry
        guard let function = registry.lookupGlobalFunction(expr.function) else {
            throw EvalError.undefinedFunction(expr.function)
        }

        // Evaluate arguments
        let args = try expr.args.map { try evaluate($0, in: context) }

        // Execute function with validation
        return try function.call(with: args)
    }

    private func evalMemberCall(_ expr: MemberCallExpr, context: Context) throws -> Value {
        // Check if this is a macro that needs special handling
        if isMacro(expr.method) {
            return try evalMacroCall(expr, context: context)
        }

        let operand = try evaluate(expr.operand, in: context)

        // Determine the type for registry lookup
        let valueType: ValueType
        if operand.asString != nil {
            valueType = .string
        } else if operand.asList != nil {
            valueType = .list
        } else if operand.asMap != nil {
            valueType = .map
        } else if operand.asInt != nil {
            valueType = .int
        } else if operand.asUInt != nil {
            valueType = .uint
        } else if operand.asDouble != nil {
            valueType = .double
        } else if operand.asBool != nil {
            valueType = .bool
        } else if operand.asBytes != nil {
            valueType = .bytes
        } else if case .null = operand {
            valueType = .null
        } else {
            throw EvalError.typeMismatch("Method \(expr.method) not available for this type")
        }

        // Look up method in registry
        guard let method = registry.lookupMethod(type: valueType, methodName: expr.method) else {
            throw EvalError.undefinedFunction("\(valueType).\(expr.method)")
        }

        // Evaluate arguments and prepend the operand (receiver)
        var args = [operand]
        args.append(contentsOf: try expr.args.map { try evaluate($0, in: context) })

        // Execute method with validation
        return try method.call(with: args)
    }

    // Check if a method name is a macro
    private func isMacro(_ methodName: String) -> Bool {
        return methodName == "exists" || methodName == "all" || methodName == "exists_one" || methodName == "filter" || methodName == "map"
    }

    // Evaluate macro method calls with special argument handling
    private func evalMacroCall(_ expr: MemberCallExpr, context: Context) throws -> Value {
        let target = try evaluate(expr.operand, in: context)

        switch expr.method {
        case "exists":
            return try evalExistsMacroCall(target: target, args: expr.args, context: context)
        case "all":
            return try evalAllMacroCall(target: target, args: expr.args, context: context)
        case "exists_one":
            return try evalExistsOneMacroCall(target: target, args: expr.args, context: context)
        case "filter":
            return try evalFilterMacroCall(target: target, args: expr.args, context: context)
        case "map":
            return try evalMapMacroCall(target: target, args: expr.args, context: context)
        default:
            throw EvalError.invalidOperation("Unknown macro: \(expr.method)")
        }
    }

    private func evalExistsMacroCall(target: Value, args: [any Expr], context: Context) throws -> Value {
        guard args.count == 2 else {
            throw EvalError.invalidOperation("exists() requires exactly 2 arguments")
        }

        guard let varIdent = args[0] as? IdentExpr else {
            throw EvalError.invalidOperation("exists() first argument must be a variable name")
        }

        guard let list = target.asList else {
            throw EvalError.typeMismatch("exists() requires list")
        }

        let variable = varIdent.name
        let predicate = args[1]

        for element in list {
            let childContext = context.createChild()
            childContext.set(variable, value: element)

            let result = try evaluate(predicate, in: childContext)
            if result.isTruthy {
                return .bool(true)
            }
        }

        return .bool(false)
    }

    private func evalAllMacroCall(target: Value, args: [any Expr], context: Context) throws -> Value {
        guard args.count == 2 else {
            throw EvalError.invalidOperation("all() requires exactly 2 arguments")
        }

        guard let varIdent = args[0] as? IdentExpr else {
            throw EvalError.invalidOperation("all() first argument must be a variable name")
        }

        guard let list = target.asList else {
            throw EvalError.typeMismatch("all() requires list")
        }

        let variable = varIdent.name
        let predicate = args[1]

        for element in list {
            let childContext = context.createChild()
            childContext.set(variable, value: element)

            let result = try evaluate(predicate, in: childContext)
            if !result.isTruthy {
                return .bool(false)
            }
        }

        return .bool(true)
    }

    private func evalExistsOneMacroCall(target: Value, args: [any Expr], context: Context) throws -> Value {
        guard args.count == 2 else {
            throw EvalError.invalidOperation("exists_one() requires exactly 2 arguments")
        }

        guard let varIdent = args[0] as? IdentExpr else {
            throw EvalError.invalidOperation("exists_one() first argument must be a variable name")
        }

        guard let list = target.asList else {
            throw EvalError.typeMismatch("exists_one() requires list")
        }

        let variable = varIdent.name
        let predicate = args[1]

        var count = 0
        for element in list {
            let childContext = context.createChild()
            childContext.set(variable, value: element)

            let result = try evaluate(predicate, in: childContext)
            if result.isTruthy {
                count += 1
                if count > 1 {
                    return .bool(false)
                }
            }
        }

        return .bool(count == 1)
    }

    private func evalFilterMacroCall(target: Value, args: [any Expr], context: Context) throws -> Value {
        guard args.count == 2 else {
            throw EvalError.invalidOperation("filter() requires exactly 2 arguments")
        }

        guard let varIdent = args[0] as? IdentExpr else {
            throw EvalError.invalidOperation("filter() first argument must be a variable name")
        }

        guard let list = target.asList else {
            throw EvalError.typeMismatch("filter() requires list")
        }

        let variable = varIdent.name
        let predicate = args[1]

        var filtered: [Value] = []
        for element in list {
            let childContext = context.createChild()
            childContext.set(variable, value: element)

            let result = try evaluate(predicate, in: childContext)
            if result.isTruthy {
                filtered.append(element)
            }
        }

        return .list(filtered)
    }

    private func evalMapMacroCall(target: Value, args: [any Expr], context: Context) throws -> Value {
        // map(var, [filter], transform)
        guard args.count == 2 || args.count == 3 else {
            throw EvalError.invalidOperation("map() requires 2 or 3 arguments")
        }

        guard let varIdent = args[0] as? IdentExpr else {
            throw EvalError.invalidOperation("map() first argument must be a variable name")
        }

        guard let list = target.asList else {
            throw EvalError.typeMismatch("map() requires list")
        }

        let variable = varIdent.name
        let filterExpr = args.count == 3 ? args[1] : nil
        let transformExpr = args.count == 3 ? args[2] : args[1]

        var result: [Value] = []
        for element in list {
            let childContext = context.createChild()
            childContext.set(variable, value: element)

            // Apply filter if present
            if let filter = filterExpr {
                let filterResult = try evaluate(filter, in: childContext)
                if !filterResult.isTruthy {
                    continue
                }
            }

            // Apply transform
            let transformed = try evaluate(transformExpr, in: childContext)
            result.append(transformed)
        }

        return .list(result)
    }

}
