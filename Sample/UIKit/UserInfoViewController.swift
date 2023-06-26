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
        let userInfo = UserInfo()
        userInfo.userID = userIDTextField.text
        userInfo.accessToken = accessTokenTextField.text
        userInfo.idTrackingIdentifier = idTrackingIdentifierTextField.text
        RInAppMessaging.registerPreference(userInfo)
        showAlert(title: "Saved Successful")
    }

    /// Checking the correct input data
    /// - Returns: Bool of is access token and ID traking identifier has value at the same time
    private func validateInput() -> Bool {
        if userIDTextField.text.isEmpty,
           accessTokenTextField.text.isEmpty,
           idTrackingIdentifierTextField.text.isEmpty {
            showAlert(title: "Invalid input format", message: "Fill least one field ")
            return false
        }

        if !accessTokenTextField.text.isEmpty && !idTrackingIdentifierTextField.text.isEmpty {
            showAlert(title: "Invalid input format",
                      message: "Couldn't use access token and ID tracking identifier at the same time")
            return false
        }
        return true
    }
}
