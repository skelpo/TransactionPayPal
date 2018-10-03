// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "TransactionPayPal",
    products: [
        .library(name: "TransactionPayPal", targets: ["TransactionPayPal"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "TransactionPayPal", dependencies: []),
        .testTarget(name: "TransactionPayPalTests", dependencies: ["TransactionPayPal"]),
    ]
)