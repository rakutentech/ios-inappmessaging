import UIKit
import RInAppMessaging

class UserInfoViewController: UIViewController {

    @IBOutlet private weak var userIDTextField: UITextField!
    @IBOutlet private weak var idTrackingIdentifierTextField: UITextField!
    @IBOutlet private weak var accessTokenTextField: UITextField!

    private let userInfo = UserInfo()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(view.endEditing)))
        RInAppMessaging.registerPreference(userInfo)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userIDTextField.text = userInfo.getUserID()
        idTrackingIdentifierTextField.text = userInfo.getIDTrackingIdentifier()
        accessTokenTextField.text = userInfo.getAccessToken()
    }

    @IBAction private func saveUserInfoAction() {
        view.endEditing(true)
        guard SDKInitHelper.isSDKInitialized else {
            showAlert(title: "alert_title_error".localized,
                      message: "alert_message_not_initialized".localized)
            return
        }
        guard validateInput() else {
            return
        }
        userInfo.userID = userIDTextField.text
        userInfo.idTrackingIdentifier = idTrackingIdentifierTextField.text
        userInfo.accessToken = accessTokenTextField.text

        showAlert(title: "alert_title_save_successful".localized)
    }

    private func validateInput() -> Bool {
        let inputError = UserInfoHelper.validateInput(
            userID: userIDTextField.text,
            idTracker: idTrackingIdentifierTextField.text,
            token: accessTokenTextField.text)

        if inputError == .duplicateTracker {
            showAlert(title: "alert_title_invalid_input".localized,
                      message: "alert_message_duplicate_identifier".localized)
            return false
        }

        return true
    }
}
