// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GalaxyShell",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "GalaxyShell",
            path: "Sources/GalaxyShell",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreWLAN"),
                .linkedFramework("IOKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
            ]
        )
    ]
)
