import SwiftUI
import RInAppMessaging

@available(iOS 13.0, *)
struct UserInfoView: View {

    @State private var userIDText: String = ""
    @State private var idTrackerText: String = ""
    @State private var accessTokenText: String = ""
    @State private var isSDKNotInitializedAlertPresented = false
    @State private var isDuplicateTrackerAlertPresented = false
    @State private var isSuccessAlertPresented = false

    private let userInfo = UserInfoHelper.sharedPreference
    private var textFields: [(title: String, text: Binding<String>)] {
        [("USER ID:", $userIDText),
         ("ID TRACKING IDENTIFIER:", $idTrackerText),
         ("ACCESS TOKEN:", $accessTokenText)]
    }

    var body: some View {
        VStack(alignment: .center) {
            ForEach(textFields, id: \.title) { textField in
                VStack(alignment: .leading) {
                    Text(textField.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.darkGray))
                    TextField("", text: textField.text) {
                        hideKeyboard()
                    }
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                }
            }
            Spacer()
            Button("SAVE", action: save)
            // using Text("") as a host view for each alert
            Text("").alert(isPresented: $isDuplicateTrackerAlertPresented) {
                Alert(title: Text("alert_title_invalid_input".localized),
                      message: Text("alert_message_duplicate_identifier".localized))
            }
            Text("").alert(isPresented: $isSDKNotInitializedAlertPresented) {
                Alert(title: Text("alert_title_error".localized),
                      message: Text("alert_message_not_initialized".localized))
            }
            Text("").alert(isPresented: $isSuccessAlertPresented) {
                Alert(title: Text("alert_title_save_successful".localized))
            }
        }
        .padding(32)
        .onAppear {
            userIDText = userInfo.getUserID() ?? ""
            idTrackerText = userInfo.getIDTrackingIdentifier() ?? ""
            accessTokenText = userInfo.getAccessToken() ?? ""
        }
    }

    private func save() {
        hideKeyboard()
        guard SDKInitHelper.isSDKInitialized else {
            isSDKNotInitializedAlertPresented = true
            return
        }
        guard validateInput() else {
            return
        }
        userInfo.userID = userIDText
        userInfo.idTrackingIdentifier = idTrackerText
        userInfo.accessToken = accessTokenText

        isSuccessAlertPresented = true
    }

    private func validateInput() -> Bool {
        let inputError = UserInfoHelper.validateInput(
            userID: userIDText,
            idTracker: idTrackerText,
            token: accessTokenText)

        if inputError == .duplicateTracker {
            isDuplicateTrackerAlertPresented = true
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
