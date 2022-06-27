import UIKit
import RInAppMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static var isTestEnvironment: Bool {
        return NSClassFromString("XCTest") != nil
    }

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if !AppDelegate.isTestEnvironment || CommandLine.arguments.contains("--uitesting") {
            MockServerHelper.setupForSampleApp()
            RInAppMessaging.configure()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.host == "secondpage" {
            NotificationCenter.default.post(name: Notification.Name("showSecondPage"), object: nil)
        }

        return true
    }
}
