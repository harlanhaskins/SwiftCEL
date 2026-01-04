// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftCEL",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "SwiftCEL",
            targets: ["SwiftCEL"]
        )
    ],
    targets: [
        .target(
            name: "SwiftCEL",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftCELTests",
            dependencies: ["SwiftCEL"]
        )
    ]
)
