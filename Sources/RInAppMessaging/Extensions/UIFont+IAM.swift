import UIKit.UIFont

/// Fonts referenced here must be pre-registered by the host application
internal extension UIFont {
    class func mPlus1RRegular(ofSize fontSize: CGFloat) -> UIFont? {
        UIFont(name: "M+1r-regular", size: fontSize)
    }

    class func mPlus1RMedium(ofSize fontSize: CGFloat) -> UIFont? {
        UIFont(name: "M+1r-medium", size: fontSize)
    }
}
