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
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .first {
            return keyScene.statusBarManager?.statusBarStyle
        }

        // Only iOS 13+ is supported
        return nil
    }
}
