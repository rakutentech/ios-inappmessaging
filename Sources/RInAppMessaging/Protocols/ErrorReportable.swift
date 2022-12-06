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
        let error = NSError.iamError(description: description, data: data, callerClass: type(of: self))

        errorDelegate?.didReceive(error: error)

        if let unwrappedData = data {
            Logger.debug(description + " (\(String(describing: unwrappedData))")
        } else {
            Logger.debug(description)
        }
    }
}

extension NSError {

    static func iamError(description: String, data: Any? = nil, callerClass: AnyClass = NSError.self) -> NSError {
        let prefix = "InAppMessaging: "
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: prefix + description]
        if let data = data {
            userInfo["data"] = data
        }

        return NSError(domain: "InAppMessaging.\(callerClass)",
                       code: 0,
                       userInfo: userInfo)
    }
}
