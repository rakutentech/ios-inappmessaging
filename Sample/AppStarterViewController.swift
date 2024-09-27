import UIKit
import SwiftUI

class AppStarterViewController: UIViewController {

    @IBOutlet weak var swiftUIButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard #available(iOS 14, *) else {
            swiftUIButton.isEnabled = false
            return
        }
    }

    @IBAction func uiKitDidTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let uiKitTabBarController = storyboard.instantiateViewController(withIdentifier: "UIKitTabBar") as? UITabBarController else {
            return
        }
        view.window?.rootViewController = uiKitTabBarController
    }

    @available(iOS 14.0, *)
    @IBAction func swiftUiDidTap(_ sender: Any) {
        let swiftUITabBarController = UIHostingController(rootView: TabBarView())
        view.window?.rootViewController = swiftUITabBarController
    }

}
