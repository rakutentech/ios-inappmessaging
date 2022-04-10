// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RInAppMessaging",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "RInAppMessaging",
            targets: ["RInAppMessaging"])
    ],
    dependencies: [
        .package(name: "RSDKUtils", url: "https://github.com/rakutentech/ios-sdkutils.git", .upToNextMinor(from: "3.0.0"))
    ],
    targets: [
        .target(
            name: "RInAppMessaging",
            dependencies: [.product(name: "RSDKUtilsMain", package: "RSDKUtils")],
            resources: [.process("Resources")]
        )
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
