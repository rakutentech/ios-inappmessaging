import UIKit
import RInAppMessaging

class UserInfoViewController: UIViewController {

    @IBOutlet private weak var userIDTextField: UITextField!
    @IBOutlet private weak var idTrackingIdentifierTextField: UITextField!
    @IBOutlet private weak var accessTokenTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(view.endEditing)))
    }

    @IBAction private func saveUserInfoAction() {
        view.endEditing(true)
        guard validateInput() else {
            return
        }
        let userInfo = UserInfo(
            userID: userIDTextField.text,
            idTrackingIdentifier: idTrackingIdentifierTextField.text,
            accessToken: accessTokenTextField.text
        )
        RInAppMessaging.registerPreference(userInfo)
        showAlert(title: "Saved Successful")
    }

    private func validateInput() -> Bool {
        let validate = UserInfoHelper.validateInput(
            userID: userIDTextField.text,
            idTracker: idTrackingIdentifierTextField.text,
            token: accessTokenTextField.text)

        if let validate {
            switch validate {
            case .emptyInput:
                showAlert(title: "Invalid input format", message: "Fill least one field")
            case .duplicateTracker:
                showAlert(title: "Invalid input format",
                          message: "Couldn't use access token and ID tracking identifier at the same time")
            }
            return false
        }
        return true
    }
}
