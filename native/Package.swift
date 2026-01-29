// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WardleyMapsNative",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "WardleyMapsApp", targets: ["WardleyMapsApp"]),
    ],
    targets: [
        // Pure data types — no dependencies
        .target(
            name: "WardleyModel",
            path: "Sources/WardleyModel"
        ),

        // DSL text → WardleyMap
        .target(
            name: "WardleyParser",
            dependencies: ["WardleyModel"],
            path: "Sources/WardleyParser"
        ),

        // Theme definitions (colours, fonts, stroke widths)
        .target(
            name: "WardleyTheme",
            dependencies: ["WardleyModel"],
            path: "Sources/WardleyTheme"
        ),

        // SwiftUI Canvas rendering
        .target(
            name: "WardleyRenderer",
            dependencies: ["WardleyModel", "WardleyTheme"],
            path: "Sources/WardleyRenderer"
        ),

        // State management, views, services
        .target(
            name: "WardleyApp",
            dependencies: [
                "WardleyModel",
                "WardleyParser",
                "WardleyTheme",
                "WardleyRenderer",
            ],
            path: "Sources/WardleyApp"
        ),

        // @main executable
        .executableTarget(
            name: "WardleyMapsApp",
            dependencies: ["WardleyApp"],
            path: "Sources/WardleyMapsApp"
        ),

        // Tests
        .testTarget(
            name: "WardleyParserTests",
            dependencies: ["WardleyParser", "WardleyModel"],
            path: "Tests/WardleyParserTests"
        ),
        .testTarget(
            name: "WardleyRendererTests",
            dependencies: ["WardleyRenderer", "WardleyModel", "WardleyTheme"],
            path: "Tests/WardleyRendererTests"
        ),
    ]
)
