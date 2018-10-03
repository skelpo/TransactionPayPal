// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "TransactionPayPal",
    products: [
        .library(name: "TransactionPayPal", targets: ["TransactionPayPal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skelpo/Transaction.git", from: "0.1.3")
    ],
    targets: [
        .target(name: "TransactionPayPal", dependencies: ["Transaction"]),
        .testTarget(name: "TransactionPayPalTests", dependencies: ["TransactionPayPal"]),
    ]
)