import class UIKit.UIDevice

/// Extension to `UIDevice` class to provide addtional initializers required by InAppMessaging.
internal extension UIDevice {
    static var deviceID: String? {
        current.identifierForVendor?.uuidString
    }
}
