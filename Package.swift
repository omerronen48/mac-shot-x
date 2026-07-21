// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacShot",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MacShotCore"),
        .executableTarget(
            name: "MacShot",
            dependencies: ["MacShotCore"]
        ),
        .testTarget(
            name: "MacShotCoreTests",
            dependencies: ["MacShotCore"]
        ),
    ]
)
