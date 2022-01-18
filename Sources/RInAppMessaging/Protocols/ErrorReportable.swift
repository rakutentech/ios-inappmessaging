import Foundation

internal protocol ErrorDelegate: AnyObject {
    func didReceive(error: NSError)
}

internal protocol ErrorReportable: AnyObject {
    var errorDelegate: ErrorDelegate? { get set }
    func reportError(description: String, data: Any?)
}

extension ErrorReportable {

    func reportError(description: String, data: Any?) {
        let prefix = "InAppMessaging: "
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: prefix + description]
        if let data = data {
            userInfo["data"] = data
        }

        let error = NSError(domain: "InAppMessaging.\(type(of: self))",
                            code: 0,
                            userInfo: userInfo)

        errorDelegate?.didReceive(error: error)

        if let unwrappedData = data {
            Logger.debug(description + " (\(String(describing: unwrappedData))")
        } else {
            Logger.debug(description)
        }
    }
}
