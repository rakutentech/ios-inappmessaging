import Foundation
import RInAppMessaging

class UserInfo: UserInfoProvider {
    var accessToken: String?
    var userID: String?
    var idTrackingIdentifier: String?

    func getAccessToken() -> String? {
        accessToken
    }

    func getUserID() -> String? {
        userID
    }

    func getIDTrackingIdentifier() -> String? {
        idTrackingIdentifier
    }
}
