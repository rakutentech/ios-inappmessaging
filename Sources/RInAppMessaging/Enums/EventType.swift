internal enum EventType: Int, Codable, Equatable {
    case invalid = 0
    case appStart
    case loginSuccessful
    case purchaseSuccessful
    case custom
    case viewAppeared = 100

    var name: String {
        switch self {
        case .invalid:
            return Constants.Event.invalid
        case .appStart:
            return Constants.Event.appStart
        case .loginSuccessful:
            return Constants.Event.loginSuccessful
        case .purchaseSuccessful:
            return Constants.Event.purchaseSuccessful
        case .custom:
            return Constants.Event.custom
        case .viewAppeared:
            return Constants.Event.viewAppeared
        }
    }
}
