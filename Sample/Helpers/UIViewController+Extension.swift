import UIKit

extension UIViewController {
    func showAlert(title: String, message: String? = "") {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }
}
