// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeminiKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "GeminiKit",
            targets: ["GeminiKit"]),
        .executable(
            name: "gemini-cli",
            targets: ["GeminiCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "GeminiKit",
            dependencies: [],
            path: "Sources/GeminiKit"
        ),
        .testTarget(
            name: "GeminiKitTests",
            dependencies: ["GeminiKit"]
        ),
        .executableTarget(
            name: "GeminiCLI",
            dependencies: [
                "GeminiKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/GeminiCLI"
        )
    ]
)