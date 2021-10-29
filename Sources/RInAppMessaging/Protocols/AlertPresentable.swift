import UIKit

/// Protocol with convenience method to display alert controller on
/// `UIApplication.keyWindow`'s root view controller
internal protocol AlertPresentable {
    func showAlert(title: String,
                   message: String,
                   style: UIAlertController.Style,
                   actions: [UIAlertAction])
}

// Default implementation
extension AlertPresentable {

    func showAlert(title: String,
                   message: String,
                   style: UIAlertController.Style,
                   actions: [UIAlertAction]) {

        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: style)
        actions.forEach { alert.addAction($0) }
        UIApplication.shared.getKeyWindow()?.rootViewController?.present(alert, animated: true)
    }
}
