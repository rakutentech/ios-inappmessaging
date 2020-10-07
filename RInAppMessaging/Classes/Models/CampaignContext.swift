/// A context object to be sent with `logEvent` API method. It can be used to add contextual information that can be reviewed later before displaying campaign related to that event.
@objc public class EventContext: NSObject {
    let id: String
    let userInfo: [AnyHashable: Any]

    public init(id: String, userInfo: [AnyHashable: Any] = [:]) {
        self.id = id
        self.userInfo = userInfo
        super.init()
    }

    static func == (lhs: EventContext, rhs: EventContext) -> Bool {
        return lhs.id == rhs.id
    }
}
