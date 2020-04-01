import Foundation

internal protocol ErrorDelegate: AnyObject {
    func didReceiveError(sender: ErrorReportable, error: NSError)
}

internal protocol ErrorReportable {
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

        errorDelegate?.didReceiveError(sender: self, error: error)

        if let unwrappedData = data {
            CommonUtility.debugPrint(description + " (\(String(describing: unwrappedData))")
        } else {
            CommonUtility.debugPrint(description)
        }
    }
}
