// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ezTime",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "ezTime", path: "Sources/ezTime")
    ]
)
