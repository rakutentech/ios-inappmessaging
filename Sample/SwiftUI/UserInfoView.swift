import SwiftUI
import RInAppMessaging

@available(iOS 13.0, *)
struct UserInfoView: View {

    @State private var userIDTextFieldText: String = ""
    @State private var idTrackerTextFieldText: String = ""
    @State private var accessTokenUserIDTextFieldText: String = ""
    @State private var isEmptyTextFieldAlertPresented = false
    @State private var isDuplicateTrackerAlertPresented = false
    @State private var isSuccessAlertPresented = false
    @State private var userInfo = UserInfo()

    init() {
        RInAppMessaging.registerPreference(userInfo)
    }

    var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text("USER ID:")
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkGray))
                TextField("", text: $userIDTextFieldText, onCommit: {
                    hideKeyboard()
                })
                .textFieldStyle(.roundedBorder)
            }
            .alert(isPresented: $isEmptyTextFieldAlertPresented) {
                Alert(title: Text("alert_invalid_input_title".localized), message: Text("alert_fill_at_least_one_field".localized))
            }
            VStack(alignment: .leading) {
                Text("ID TRACKING IDENTIFIER:")
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkGray))
                TextField("", text: $idTrackerTextFieldText, onCommit: {
                    hideKeyboard()
                })
                .textFieldStyle(.roundedBorder)
            }
            .alert(isPresented: $isDuplicateTrackerAlertPresented) {
                Alert(title: Text("alert_invalid_input_title".localized), message: Text("alert_duplicate_identifier".localized))
            }
            VStack(alignment: .leading) {
                Text("ACCESS TOKEN:")
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkGray))
                TextField("", text: $accessTokenUserIDTextFieldText, onCommit: {
                    hideKeyboard()
                })
                    .textFieldStyle(.roundedBorder)
            }
            Spacer()
            Button("SAVE") {
                hideKeyboard()
                guard validateInput() else {
                    return
                }
                userInfo = UserInfo(
                    userID: userIDTextFieldText,
                    idTrackingIdentifier: idTrackerTextFieldText,
                    accessToken: accessTokenUserIDTextFieldText
                )
                isSuccessAlertPresented = true
            }
            .alert(isPresented: $isSuccessAlertPresented) {
                Alert(title: Text("alert_saved_successful_title".localized))
            }
        }
        .padding(32)
        .onAppear {
            userIDTextFieldText = userInfo.getUserID() ?? ""
            idTrackerTextFieldText = userInfo.getIDTrackingIdentifier() ?? ""
            accessTokenUserIDTextFieldText = userInfo.getAccessToken() ?? ""
        }
    }

    private func validateInput() -> Bool {
        let validate = UserInfoHelper.validateInput(
            userID: userIDTextFieldText,
            idTracker: idTrackerTextFieldText,
            token: accessTokenUserIDTextFieldText)

        if let validate {
            switch validate {
            case .emptyInput:
                isEmptyTextFieldAlertPresented = true
            case .duplicateTracker:
                isDuplicateTrackerAlertPresented = true
            }
            return false
        }
        return true
    }

}

@available(iOS 13.0, *)
struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView()
    }
}
