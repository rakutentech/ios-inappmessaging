import UIKit
import SwiftUI

class AppStarterViewController: UIViewController {

    @available(iOS 13.0, *)
    @IBAction func uiKitDidTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let uiKitTabBarController = storyboard.instantiateViewController(identifier: "UIKitTabBar") as? UITabBarController else {
            return
        }
        UIApplication.shared.windows.first?.rootViewController = uiKitTabBarController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

    @available(iOS 13.0, *)
    @IBAction func swiftUiDidTap(_ sender: Any) {
        let swiftUITabBarController = UIHostingController(rootView: TabBarView())
        UIApplication.shared.windows.first?.rootViewController = swiftUITabBarController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

}
