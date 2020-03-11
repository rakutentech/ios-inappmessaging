/// Enum of impression events.
internal enum ImpressionType: Int, Encodable {
    case invalid = 0
    case impression
    case actionOne
    case actionTwo
    case exit
    case clickContent
    case optOut
}
