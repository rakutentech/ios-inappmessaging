import UIKit

class AppStarterViewController: UIViewController {

    @available(iOS 13.0, *)
    @IBAction func uiKitDidTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let uiKitTabBarController = storyboard.instantiateViewController(identifier: "UIKitTabBar") as! UITabBarController
        uiKitTabBarController.modalPresentationStyle = .fullScreen
        self.present(uiKitTabBarController, animated: false, completion: nil)
    }

    @IBAction func swiftUiDidTap(_ sender: Any) {
    }

}
