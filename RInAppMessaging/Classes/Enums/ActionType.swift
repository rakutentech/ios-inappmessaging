internal enum ActionType: Int, Decodable {
    case invalid = 0
    case redirect
    case deeplink
    case close
}
