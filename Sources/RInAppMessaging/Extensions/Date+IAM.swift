import struct Foundation.Date

/// Extension to Date class to provide computed properties required by InAppMessaging.
internal extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
