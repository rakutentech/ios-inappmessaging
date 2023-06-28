import Foundation
struct UserInfoHelper {
    enum ErrorType {
        case emptyInput
        case duplicateTracker
    }

    /// Checking the correct input data
    /// - Returns: Bool of is access token and ID traking identifier has value at the same time
    static func validateInput(userID: String?, idTracker: String?, token: String?) -> ErrorType? {
        if userID.isEmpty,
           idTracker.isEmpty,
           token.isEmpty {
            return .emptyInput
        }

        if !idTracker.isEmpty && !token.isEmpty {
            return .duplicateTracker
        }
        return nil
    }
}
