import Testing
@testable import SwiftCEL

@Suite("Value Tests")
struct ValueTests {

    // MARK: - Value Equality

    @Test("Integer value equality")
    func testIntegerEquality() throws {
        let v1 = Value.int(42)
        let v2 = Value.int(42)
        let v3 = Value.int(43)

        #expect(v1 == v2)
        #expect(v1 != v3)
    }

    @Test("String value equality")
    func testStringEquality() throws {
        let v1 = Value.string("hello")
        let v2 = Value.string("hello")
        let v3 = Value.string("world")

        #expect(v1 == v2)
        #expect(v1 != v3)
    }

    @Test("Boolean value equality")
    func testBooleanEquality() throws {
        let v1 = Value.bool(true)
        let v2 = Value.bool(true)
        let v3 = Value.bool(false)

        #expect(v1 == v2)
        #expect(v1 != v3)
    }

    @Test("Null value equality")
    func testNullEquality() throws {
        let v1 = Value.null
        let v2 = Value.null

        #expect(v1 == v2)
    }

    @Test("Different types not equal")
    func testDifferentTypesNotEqual() throws {
        let int = Value.int(42)
        let str = Value.string("42")
        let bool = Value.bool(true)

        #expect(int != str)
        #expect(int != bool)
        #expect(str != bool)
    }

    // MARK: - Type Checking

    @Test("Type checking helpers")
    func testTypeChecking() throws {
        #expect(Value.int(42).isInt)
        #expect(!Value.int(42).isString)

        #expect(Value.string("hello").isString)
        #expect(!Value.string("hello").isInt)

        #expect(Value.bool(true).isBool)
        #expect(!Value.bool(true).isInt)

        #expect(Value.null.isNull)
        #expect(!Value.null.isInt)

        #expect(Value.list([]).isList)
        #expect(!Value.list([]).isMap)

        #expect(Value.map([:]).isMap)
        #expect(!Value.map([:]).isList)
    }

    // MARK: - Value Extraction

    @Test("Extract integer value")
    func testExtractInt() throws {
        let value = Value.int(42)
        #expect(value.asInt == 42)
        #expect(value.asString == nil)
    }

    @Test("Extract string value")
    func testExtractString() throws {
        let value = Value.string("hello")
        #expect(value.asString == "hello")
        #expect(value.asInt == nil)
    }

    @Test("Extract boolean value")
    func testExtractBool() throws {
        let value = Value.bool(true)
        #expect(value.asBool == true)
        #expect(value.asInt == nil)
    }

    @Test("Extract list value")
    func testExtractList() throws {
        let list = [Value.int(1), Value.int(2), Value.int(3)]
        let value = Value.list(list)
        #expect(value.asList?.count == 3)
        #expect(value.asInt == nil)
    }

    @Test("Extract map value")
    func testExtractMap() throws {
        let map = ["key": Value.string("value")]
        let value = Value.map(map)
        #expect(value.asMap?["key"] == Value.string("value"))
        #expect(value.asInt == nil)
    }

    // MARK: - Truthiness

    @Test("Boolean truthiness")
    func testBooleanTruthiness() throws {
        #expect(Value.bool(true).isTruthy == true)
        #expect(Value.bool(false).isTruthy == false)
    }

    @Test("Non-boolean truthiness")
    func testNonBooleanTruthiness() throws {
        // In CEL, only false and null are falsy
        #expect(Value.int(0).isTruthy == true)
        #expect(Value.string("").isTruthy == true)
        #expect(Value.null.isTruthy == false)
        #expect(Value.list([]).isTruthy == true)
    }

    // MARK: - String Representation

    @Test("Value description")
    func testValueDescription() throws {
        #expect(Value.int(42).description == "42")
        #expect(Value.string("hello").description == "\"hello\"")
        #expect(Value.bool(true).description == "true")
        #expect(Value.null.description == "null")
        #expect(Value.list([Value.int(1), Value.int(2)]).description.contains("1"))
    }
}
