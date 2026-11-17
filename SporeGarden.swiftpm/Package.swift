// swift-tools-version: 5.8

// This is an "App Playground" package. Open the SporeGarden.swiftpm folder
// in Xcode (or Swift Playgrounds) and it runs as a normal iOS app.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Spore Garden",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Spore Garden",
            targets: ["AppModule"],
            bundleIdentifier: "com.example.sporegarden",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .leaf),
            accentColor: .presetColor(.orange),
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
