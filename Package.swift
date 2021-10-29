// swift-tools-version:5.3
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
        .package(url: "https://github.com/rakutentech/ios-sdkutils.git", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        .target(
            name: "RInAppMessaging",
            dependencies: [.product(name: "RSDKUtilsMain", package: "ios-sdkutils")],
            resources: [.process("Resources")]
        )
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
