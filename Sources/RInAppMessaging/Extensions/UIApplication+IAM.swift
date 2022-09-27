import UIKit

extension UIApplication {

    func getKeyWindow() -> UIWindow? {
        var keySceneWindow: UIWindow?
        if #available(iOS 13.0, *) {
            keySceneWindow = connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .first(where: { $0.isKeyWindow })
        }

        return keySceneWindow ?? windows.first { $0.isKeyWindow }
    }

    func getCurrentStatusBarStyle() -> UIStatusBarStyle? {
        if #available(iOS 13.0, *),
           let keyScene = connectedScenes
                .filter({ $0.activationState != .unattached })
                .compactMap({ $0 as? UIWindowScene })
                .first {

            var style = keyScene.statusBarManager?.statusBarStyle
            // `default` style doesn't tell us anything, so we can fallback to the most common pattern:
            // light status bar content in dark mode and dark content in light mode.
            if style == .default, let keyWindow = getKeyWindow() {
                let isDarkMode = keyWindow.traitCollection.userInterfaceStyle == .dark
                style = isDarkMode ? .lightContent : .darkContent
            }
            return style
        }

        // Only iOS 13+ is supported
        return nil
    }
}
