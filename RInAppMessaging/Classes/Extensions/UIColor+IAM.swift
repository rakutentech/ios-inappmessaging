/// Extension to `UIColor` class to provide addtional initializers required by InAppMessaging.
internal extension UIColor {

    /// Convert hexadecimal string to `UIColor` object.
    /// Can fail if string format is invalid.
    ///
    /// Following formats are accepted:
    /// * 0x...
    /// * 0X...
    /// * #...
    ///
    /// String value must be a six-digit, three-byte hexadecimal number
    /// - Parameter string: Color value in hex format
    /// - Parameter alpha: alpha value to append to the `UIColor` object
    convenience init?(fromHexString string: String, alpha: CGFloat = 1.0) {
        var hexString = string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 6,
            let rgbValue = UInt32(hexString, radix: 16) else {
            return nil
        }

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
