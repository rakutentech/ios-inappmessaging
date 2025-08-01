// swift-tools-version:5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RInAppMessaging",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "RInAppMessaging",
            targets: ["RInAppMessaging"])
    ],
    dependencies: [
        .package(url: "https://github.com/rakutentech/ios-sdkutils.git", branch: "master")
    ],
    targets: [
        .target(
            name: "RInAppMessaging",
            dependencies: [.product(name: "RSDKUtilsMain", package: "ios-sdkutils"),
                           .product(name: "REventLogger", package: "ios-sdkutils")],
            resources: [.process("Resources")]
        )
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
