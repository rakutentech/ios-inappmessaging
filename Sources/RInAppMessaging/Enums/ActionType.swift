internal enum ActionType: Int, Codable {
    case invalid = 0
    case redirect
    case deeplink
    case close
    case pushPrimer
}
