// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacShot",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "MacShotCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "MacShot",
            dependencies: ["MacShotCore"],
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MacShotCoreTests",
            dependencies: ["MacShotCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
