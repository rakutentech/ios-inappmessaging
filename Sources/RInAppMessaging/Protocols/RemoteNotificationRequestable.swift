import UserNotifications
import class UIKit.UIApplication

protocol RemoteNotificationRequestable {
    func requestAuthorization(options: UNAuthorizationOptions,
                              completionHandler: @escaping (Bool, Error?) -> Void)
    func registerForRemoteNotifications()
    func getAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void)
}

extension RemoteNotificationRequestable {
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}

extension UNUserNotificationCenter: RemoteNotificationRequestable {
    func getAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void) {
        getNotificationSettings { settings in
            completionHandler(settings.authorizationStatus)
        }
    }
}

protocol UserNotificationCenter {
    func getNotificationSettings(completionHandler: @escaping (NotificationSettingsProtocol) -> Void)
}

protocol NotificationSettingsProtocol {
    var authorizationStatus: UNAuthorizationStatus { get }
}

class UNUserNotificationService: UserNotificationCenter {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.center = center
    }

    func getNotificationSettings(completionHandler: @escaping (NotificationSettingsProtocol) -> Void) {
        center.getNotificationSettings { settings in
            completionHandler(settings as NotificationSettingsProtocol)
        }
    }
}

extension UNNotificationSettings: NotificationSettingsProtocol {}
