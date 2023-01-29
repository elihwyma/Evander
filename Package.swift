// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Evander",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "Evander",
            targets: ["Evander"]),
    ],
    targets: [
        .target(
            name: "Evander",
            dependencies: [])
    ]
)
