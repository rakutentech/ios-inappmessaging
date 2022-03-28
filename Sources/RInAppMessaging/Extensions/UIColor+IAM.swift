import UIKit
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif

/// Extension to `UIColor` class to provide addtional initializers required by InAppMessaging.
internal extension UIColor {

    static var statusBarOverlayColor: UIColor {
        if UIApplication.shared.getCurrentStatusBarStyle() == .lightContent {
            return black.withAlphaComponent(0.4)
        } else {
            return white.withAlphaComponent(0.4)
        }
    }

    static let buttonBorderDefaultColor = UIColor(hexString: "#D1D1D1")!

    /// Returns perceived brightness value based on [Darel Rex Finley's HSP Colour Model](http://alienryderflex.com/hsp.html) from 0 to 1.0 (max brightness)
    var brightness: CGFloat {
        var (r,g,b) = (CGFloat(0), CGFloat(0), CGFloat(0))
        getRed(&r, green: &g, blue: &b, alpha: nil) // works with RGB, HSB, extendedGray
        let (rHSPFactor, gHSPFactor, bHSPFactor) = (CGFloat(0.241), CGFloat(0.691), CGFloat(0.068))
        return sqrt(r*r*rHSPFactor + g*g*gHSPFactor + b*b*bHSPFactor)
    }

    /// Returns true if colour is perceived to be bright
    /// Can be used for determining contrasting text colour on backgrounds for high visibility
    var isBright: Bool {
        let threshold: CGFloat = 130/255
        return brightness > threshold
    }

}
