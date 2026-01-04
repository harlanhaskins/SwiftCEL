import Testing
@testable import SwiftCEL

@Suite("Context Tests")
struct ContextTests {

    // MARK: - Basic Variable Binding

    @Test("Set and get variable")
    func testBasicBinding() throws {
        let context = Context()
        context.set("x", value: .int(42))

        #expect(context.get("x") == .int(42))
    }

    @Test("Get non-existent variable returns nil")
    func testNonExistentVariable() throws {
        let context = Context()
        #expect(context.get("nonexistent") == nil)
    }

    @Test("Multiple variables")
    func testMultipleVariables() throws {
        let context = Context()
        context.set("x", value: .int(42))
        context.set("name", value: .string("Alice"))
        context.set("active", value: .bool(true))

        #expect(context.get("x") == .int(42))
        #expect(context.get("name") == .string("Alice"))
        #expect(context.get("active") == .bool(true))
    }

    @Test("Override variable")
    func testOverrideVariable() throws {
        let context = Context()
        context.set("x", value: .int(42))
        #expect(context.get("x") == .int(42))

        context.set("x", value: .int(100))
        #expect(context.get("x") == .int(100))
    }

    // MARK: - Nested Scopes

    @Test("Child context inherits from parent")
    func testChildInheritance() throws {
        let parent = Context()
        parent.set("x", value: .int(42))
        parent.set("y", value: .int(10))

        let child = parent.createChild()

        // Child can access parent variables
        #expect(child.get("x") == .int(42))
        #expect(child.get("y") == .int(10))
    }

    @Test("Child context shadows parent variable")
    func testChildShadowing() throws {
        let parent = Context()
        parent.set("x", value: .int(42))

        let child = parent.createChild()
        child.set("x", value: .int(100))

        // Child sees its own value
        #expect(child.get("x") == .int(100))

        // Parent still has original value
        #expect(parent.get("x") == .int(42))
    }

    @Test("Nested child contexts")
    func testNestedChildren() throws {
        let root = Context()
        root.set("a", value: .int(1))

        let child1 = root.createChild()
        child1.set("b", value: .int(2))

        let child2 = child1.createChild()
        child2.set("c", value: .int(3))

        // child2 can access all variables
        #expect(child2.get("a") == .int(1))
        #expect(child2.get("b") == .int(2))
        #expect(child2.get("c") == .int(3))

        // child1 cannot access child2's variables
        #expect(child1.get("c") == nil)

        // root cannot access children's variables
        #expect(root.get("b") == nil)
        #expect(root.get("c") == nil)
    }

    // MARK: - Initialization

    @Test("Initialize with bindings")
    func testInitWithBindings() throws {
        let context = Context(bindings: [
            "x": .int(42),
            "name": .string("Alice"),
            "active": .bool(true)
        ])

        #expect(context.get("x") == .int(42))
        #expect(context.get("name") == .string("Alice"))
        #expect(context.get("active") == .bool(true))
    }

    @Test("Empty context")
    func testEmptyContext() throws {
        let context = Context()
        #expect(context.get("anything") == nil)
    }
}
