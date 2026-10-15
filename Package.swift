// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClipVault",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClipVault",
            path: "Sources/ClipVault",
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .testTarget(
            name: "ClipVaultTests",
            dependencies: ["ClipVault"],
            path: "Tests/ClipVaultTests"
        ),
    ]
)
