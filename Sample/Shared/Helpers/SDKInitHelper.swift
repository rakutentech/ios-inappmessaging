import Foundation
@testable import RInAppMessaging

enum SDKInitHelper {
    static var isSDKInitialized: Bool {
        RInAppMessaging.initializedModule != nil
    }
}
