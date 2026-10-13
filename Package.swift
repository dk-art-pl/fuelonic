// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Fuelonic",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "Fuelonic",
            path: "Sources/Fuelonic",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
