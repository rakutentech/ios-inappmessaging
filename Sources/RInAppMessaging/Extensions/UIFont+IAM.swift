import UIKit.UIFont

/// Fonts referenced here must be pre-registered by the host application
internal extension UIFont {
    static func iamRegular(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFontName = BundleInfo.customFontNameRegularWeight,
                let customFont = UIFont(name: customFontName, size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return customFont
    }

    static func iamMedium(ofSize fontSize: CGFloat) -> UIFont {
        guard let customFontName = BundleInfo.customFontNameMediumWeight,
                let customFont = UIFont(name: customFontName, size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return customFont
    }
}
