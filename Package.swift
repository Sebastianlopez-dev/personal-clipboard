// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TahoeClip",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "ClipCore", targets: ["ClipCore"]),
        .executable(name: "TahoeClip", targets: ["TahoeClip"]),
        .executable(name: "clipctl", targets: ["clipctl"])
    ],
    targets: [
        .target(name: "ClipCore"),
        .executableTarget(
            name: "TahoeClip",
            dependencies: ["ClipCore"],
            linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("Carbon")]
        ),
        .executableTarget(
            name: "clipctl",
            dependencies: ["ClipCore"],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .testTarget(name: "ClipCoreTests", dependencies: ["ClipCore"]),
        .testTarget(name: "TahoeClipTests", dependencies: ["TahoeClip", "ClipCore"])
    ]
)
