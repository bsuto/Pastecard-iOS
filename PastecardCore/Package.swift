// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PastecardCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "PastecardCore",
            targets: ["PastecardCore"]),
    ],
    targets: [
        .target(
            name: "PastecardCore")
    ]
)
