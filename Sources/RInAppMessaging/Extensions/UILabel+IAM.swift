import UIKit

/// Extension to `UILabel` class to provide computed properties required by InAppMessaging.
internal extension UILabel {
    /// Set the line spacing when a label display is using two or more lines.
    /// - Parameter lineSpacing: The value of the spacing for each line. Defaults to 0.
    func setLineSpacing(lineSpacing: CGFloat = 0.0) {

        guard let labelText = self.text else {
            return
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        let attributedString: NSMutableAttributedString
        if let attributedText, attributedText.length > 0 {
            attributedString = NSMutableAttributedString(attributedString: attributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                      value: paragraphStyle,
                                      range: NSRange(location: 0, length: attributedString.length))

        self.attributedText = attributedString
    }
}
