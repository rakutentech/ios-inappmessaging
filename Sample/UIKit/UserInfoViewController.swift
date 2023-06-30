import UIKit
import RInAppMessaging

class UserInfoViewController: UIViewController {

    @IBOutlet private weak var userIDTextField: UITextField!
    @IBOutlet private weak var idTrackingIdentifierTextField: UITextField!
    @IBOutlet private weak var accessTokenTextField: UITextField!
    private var userInfo: UserInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(view.endEditing)))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userIDTextField.text = userInfo?.getUserID()
        idTrackingIdentifierTextField.text = userInfo?.getIDTrackingIdentifier()
        accessTokenTextField.text = userInfo?.getAccessToken()
    }

    @IBAction private func saveUserInfoAction() {
        view.endEditing(true)
        guard validateInput() else {
            return
        }
        if userInfo == nil {
            updateUserInfoValue()
            RInAppMessaging.registerPreference(userInfo!)
        } else {
            updateUserInfoValue()
        }
        showAlert(title: "alert_saved_successful_title".localized)
    }

    private func updateUserInfoValue() {
        userInfo = UserInfo(
            userID: userIDTextField.text,
            idTrackingIdentifier: idTrackingIdentifierTextField.text,
            accessToken: accessTokenTextField.text
        )
    }

    private func validateInput() -> Bool {
        let validate = UserInfoHelper.validateInput(
            userID: userIDTextField.text,
            idTracker: idTrackingIdentifierTextField.text,
            token: accessTokenTextField.text)

        if let validate {
            switch validate {
            case .emptyInput:
                showAlert(title: "alert_invalid_input_title".localized, message: "alert_fill_at_least_one_field".localized)
            case .duplicateTracker:
                showAlert(title: "alert_invalid_input_title".localized,
                          message: "alert_duplicate_identifier".localized)
            }
            return false
        }
        return true
    }
}
