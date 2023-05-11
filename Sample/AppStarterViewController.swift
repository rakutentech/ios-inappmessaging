import UIKit
import SwiftUI

class AppStarterViewController: UIViewController {

    @IBAction func uiKitDidTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let uiKitTabBarController = storyboard.instantiateViewController(identifier: "UIKitTabBar") as? UITabBarController else {
            return
        }
        uiKitTabBarController.modalPresentationStyle = .fullScreen
        self.present(uiKitTabBarController, animated: false, completion: nil)
    }

    @IBAction func swiftUiDidTap(_ sender: Any) {
        let swiftUITabBarController = UIHostingController(rootView: TabBarView())
        swiftUITabBarController.modalPresentationStyle = .fullScreen
        self.present(swiftUITabBarController, animated: false, completion: nil)
    }

}
