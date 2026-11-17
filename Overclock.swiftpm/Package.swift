// swift-tools-version: 5.8

// Overclock: an "App Playground" package. Double-click Overclock.swiftpm to open it in Xcode.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Overclock",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Overclock",
            targets: ["AppModule"],
            bundleIdentifier: "com.example.overclock",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .sparkle),
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
