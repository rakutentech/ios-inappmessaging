import UIKit

/// Extension to `UIColor` class to provide addtional initializers required by InAppMessaging.
internal extension UIColor {

    static var statusBarOverlayColor: UIColor {
        if UIApplication.shared.getCurrentStatusBarStyle() == .lightContent {
            return black.withAlphaComponent(0.4)
        } else {
            return white.withAlphaComponent(0.4)
        }
    }

    /// Returns perceived brightness value based on [Darel Rex Finley's HSP Colour Model](http://alienryderflex.com/hsp.html)
    var brightness: CGFloat {
        var (r,g,b) = (CGFloat(0), CGFloat(0), CGFloat(0))
        getRed(&r, green: &g, blue: &b, alpha: nil)
        return sqrt(r*r*0.241 + g*g*0.691 + b*b*0.068)
    }

    /// Returns true if colour is perceived to be bright
    var isBright: Bool {
        // https://www.nbdtech.com/Blog/archive/2008/04/27/Calculating-the-Perceived-Brightness-of-a-Color.aspx
        let threshold: CGFloat = 130
        return brightness < threshold ? true : false
    }

}
