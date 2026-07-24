// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacShot",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MacShotCore"),
        .executableTarget(
            name: "MacShot",
            dependencies: ["MacShotCore"],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "MacShotCoreTests",
            dependencies: ["MacShotCore"]
        ),
    ]
)
