// swift-tools-version: 5.9
// NOTE: This Package.swift is for reference only.
// The actual app must be built using Xcode with iOS/watchOS targets.
// See README.md for setup instructions.

import PackageDescription

let package = Package(
    name: "HabitForge",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "HabitForge", targets: ["HabitForge"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HabitForge",
            dependencies: [],
            path: "HabitForge"
        )
    ]
)
