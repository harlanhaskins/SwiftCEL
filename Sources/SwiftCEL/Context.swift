import Foundation

// MARK: - Context

/// Evaluation context that holds variable bindings
public class Context {
    private var bindings: [String: Value]
    private var parent: Context?

    /// Create an empty context
    public init() {
        self.bindings = [:]
        self.parent = nil
    }

    /// Create a context with initial bindings
    public init(bindings: [String: Value]) {
        self.bindings = bindings
        self.parent = nil
    }

    /// Create a child context that inherits from this context
    private init(parent: Context) {
        self.bindings = [:]
        self.parent = parent
    }

    /// Get a variable value from the context
    /// Searches up the parent chain if not found in current scope
    public func get(_ name: String) -> Value? {
        if let value = bindings[name] {
            return value
        }

        // Search in parent context
        return parent?.get(name)
    }

    /// Set a variable value in the current context
    public func set(_ name: String, value: Value) {
        bindings[name] = value
    }

    /// Create a child context that inherits from this context
    /// Used for scoped evaluation (e.g., in macros)
    public func createChild() -> Context {
        return Context(parent: self)
    }
}
