import Foundation

// Testable import is required to access `isInitialized` internal var
@testable import RInAppMessaging

enum SDKInitHelper {
    static var isSDKInitialized: Bool {
        RInAppMessaging.isInitialized
    }
}
