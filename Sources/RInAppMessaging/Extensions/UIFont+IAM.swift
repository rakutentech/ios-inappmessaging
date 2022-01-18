import UIKit.UIFont

/// Fonts referenced here must be pre-registered by the host application
internal extension UIFont {
    static func iamTitle(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFontName = BundleInfo.customFontNameTitle,
                let customFont = UIFont(name: customFontName, size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return customFont
    }

    static func iamText(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFontName = BundleInfo.customFontNameText,
                let customFont = UIFont(name: customFontName, size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return customFont
    }

    static func iamButton(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFontName = BundleInfo.customFontNameButton,
                let customFont = UIFont(name: customFontName, size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return customFont
    }
}
