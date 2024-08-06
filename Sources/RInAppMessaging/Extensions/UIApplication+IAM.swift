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
    
    private static let notificationSettingsURL: URL? = {
        var urlString: String?

        if #available(iOS 16, *) {
            urlString = UIApplication.openNotificationSettingsURLString
        }
        if #available(iOS 15.4, *) {
            urlString = UIApplicationOpenNotificationSettingsURLString
        }
        if #available(iOS 8.0, *) {
            urlString = UIApplication.openSettingsURLString
        }
        
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return nil
        }

        return url
    }()

    func openAppNotificationSettings() {
        guard let url = Self.notificationSettingsURL else {
            return
        }
        self.open(url)
    }
}
