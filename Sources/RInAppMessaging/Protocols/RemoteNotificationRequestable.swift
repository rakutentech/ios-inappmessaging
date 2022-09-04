import UserNotifications
import class UIKit.UIApplication

protocol RemoteNotificationRequestable {
    func requestAuthorization(options: UNAuthorizationOptions,
                              completionHandler: @escaping (Bool, Error?) -> Void)
    func registerForRemoteNotifications()
}

extension RemoteNotificationRequestable {
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}

extension UNUserNotificationCenter: RemoteNotificationRequestable { }
