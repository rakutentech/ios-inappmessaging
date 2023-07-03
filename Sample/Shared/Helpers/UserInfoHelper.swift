import Foundation
struct UserInfoHelper {
    enum ErrorType {
        case duplicateTracker
    }

    static func validateInput(userID: String?, idTracker: String?, token: String?) -> ErrorType? {
        guard idTracker.isEmpty || token.isEmpty else {
            return .duplicateTracker
        }
        return nil
    }
}
