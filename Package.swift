// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Evander",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .tvOS(.v11),
        .watchOS(.v4)
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
