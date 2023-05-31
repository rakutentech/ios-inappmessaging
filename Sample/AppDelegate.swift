import UIKit
import RInAppMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static var isTestEnvironment: Bool {
        NSClassFromString("XCTest") != nil
    }

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if !AppDelegate.isTestEnvironment {
            // To mock API using ping.json file, uncomment the line below and enable `RIAM_CONFIG_URL` override in Example-Debug.xcconfig
            // MockServerHelper.setupForSampleApp()
        }
        if CommandLine.arguments.contains("--uitesting") {
            RInAppMessaging.configure(enableTooltipFeature: true)
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
