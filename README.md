# SwiftCEL

A Swift implementation of the [Common Expression Language](https://cel.dev)
for locally evaluating expression predicates against in-memory data.

This is a mostly-full and well-tested implementation of the CEL spec and
supports all the native operations for lists and strings and also supports
adding custom operations to evaluate with your own functions.

> Note that SwiftCEL is currently untyped, and doesn't have type metadata operators
> that exist in the full CEL spec.

## Usage

You can evaluate a query against custom data by inserting the variables you intend to query
over into a `Context` and then passing that to an `Evaluator`.

Whatever bindings you make available in the context will be available to the query.

```swift
import SwiftCEL

func evaluateQuery(_ query: String, against contact: Contact) -> Bool {
    var bindings: [String: Value] = [
        "name": .string(contact.name),
        "emailAddress": .string(contact.emailAddress),
        "phoneNumber": .string(contact.phoneNumber)
    ]

    if let address = contact.address {
        var address: [String: Value] = [
            "street": .string(address.street),
            "city": .string(address.city),
            "state", .string(address.state),
            "postalCode": .string(address.postalCode),
            "formattedAddress": .string(address.format())
        ]
        bindings["address"] = .map(address)
    }

    let context = Context(bindings: bindings)

    // The result comes back as a CEL expression; custom functions can return
    // CEL expression values.
    let result = Evaluator.evaluate(query, in: context)

    // `isTruthy` is only false for null or .bool(false)
    return result.isTruthy
}
```

Once you've set up your evaluation environment, you can run arbitrary queries
against arbitrary data.

```swift

let contact = Contact(
    name: "Harlan Haskins",
    phoneNumber: "+15555555555",
    emailAddress: "harlan@harlanhaskins.com",
    address: Address(
        street: "350 Fifth Ave", // not my real address, just fyi
        city: "New York",
        state: "New York",
        postalCode: "10118"
    )
)

evaluateQuery(#"phoneNumber.startsWith("+1")"#, against: contact) // true
evaluateQuery(#"phoneNumber.matches(".*555.*")"#, against: contact) // true
evaluateQuery(#"address.street.contains("Sixth")"#, against: contact) // false
```

## Installation

Add SwiftCEL to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/harlanhaskins/SwiftCEL.git", from: "0.1.0")
]
```

## License

SwiftCEL is released under the MIT license, a copy of which is in this repository.
