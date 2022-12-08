import UIKit
import RInAppMessaging

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(goToSecondPage(_:)),
                                               name: Notification.Name("showSecondPage"),
                                               object: nil)
    }

    @IBAction func purchaseSuccessfulButton(_ sender: Any) {

        let purchaseEvent = PurchaseSuccessfulEvent()
        _ = purchaseEvent.setPurchaseAmount(50)
        _ = purchaseEvent.setItemList(["box", "hammer"])
        _ = purchaseEvent.setCurrencyCode("USD")
        _ = purchaseEvent.setNumberOfItems(2)

        RInAppMessaging.logEvent(purchaseEvent)
    }
    @IBAction func loginSuccessfulButton(_ sender: Any) {
        RInAppMessaging.logEvent(LoginSuccessfulEvent())
    }

    @IBAction func appStartButton(_ sender: Any) {
        RInAppMessaging.logEvent(AppStartEvent())
    }

    @IBAction func goToSecondPage(_ sender: Any) {
        // Register Nib
        let newViewController = SecondPageViewController(nibName: "SecondPageViewController", bundle: nil)
        self.present(newViewController, animated: true, completion: nil)
    }
}
