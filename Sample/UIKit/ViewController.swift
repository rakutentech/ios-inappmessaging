import UIKit
@testable import RInAppMessaging

class ViewController: UIViewController {

    override func awakeFromNib() {
        super.awakeFromNib()
        tabBarItem.accessibilityIdentifier = "tabbar.button.1"
        tabBarController?.tabBar.updateItemIdentifiers()
    }

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

    @IBAction func initWithTooltip(_ sender: Any) {
        initSDK(enableTooltipFeature: true)
    }

    @IBAction func initWithoutTooltip(_ sender: Any) {
        initSDK(enableTooltipFeature: false)
    }

    private func initSDK(enableTooltipFeature: Bool) {
        guard !SDKInitHelper.isSDKInitialized else {
            showInitFailedAlert()
            return
        }
        RInAppMessaging.configure(enableTooltipFeature: enableTooltipFeature)
        showInitFinishedAlert()
    }

    private func showInitFinishedAlert() {
        let alert = UIAlertController(title: "alert_message_init_successful".localized,
                                      message: nil,
                                      preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }

    private func showInitFailedAlert() {
        let alert = UIAlertController(title: "alert_title_error".localized,
                                      message: "alert_message_already_initialized".localized,
                                      preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }
}
