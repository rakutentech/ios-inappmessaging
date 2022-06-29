import UIKit
import RInAppMessaging
import OSLog

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(goToSecondPage(_:)),
                                               name: Notification.Name("showSecondPage"),
                                               object: nil)
        RInAppMessaging.onVerifyContext = { (contexts: [String], campaignTitle: String) in
            if campaignTitle.contains("Future") {
                os_log("purchase trigger 1")
            }
            return true
        }
        sleep(8)
    }

    @IBAction func purchaseSuccessfulButton(_ sender: Any) {
        os_log("purchase trigger 0")
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
    @IBAction func customTestButton(_ sender: Any) {
        RInAppMessaging.logEvent(
            CustomEvent(
                withName: "second activity",
                withCustomAttributes: [CustomAttribute(withKeyName: "click", withBoolValue: true)]
            )
        )
    }

    @IBAction func appStartButton(_ sender: Any) {
        RInAppMessaging.logEvent(AppStartEvent())
    }

    @IBAction func goToSecondPage(_ sender: Any) {
        // Register Nib
        os_log("second page 0")
        let newViewController = SecondPageViewController(nibName: "SecondPageViewController", bundle: nil)
        self.present(newViewController, animated: true) {
            os_log("second page 1")
        }
    }
}
