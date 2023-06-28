import Foundation
import RInAppMessaging

class UserInfo: UserInfoProvider {
    var accessToken: String?
    var userID: String?
    var idTrackingIdentifier: String?

    init(userID: String? = nil, idTrackingIdentifier: String? = nil, accessToken: String? = nil) {
        self.accessToken = accessToken
        self.userID = userID
        self.idTrackingIdentifier = idTrackingIdentifier
    }

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
