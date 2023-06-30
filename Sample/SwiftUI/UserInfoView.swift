import SwiftUI
import RInAppMessaging

@available(iOS 13.0, *)
struct UserInfoView: View {

    @State private var userIDTextFieldText: String = ""
    @State private var idTrackerTextFieldText: String = ""
    @State private var accessTokenuserIDTextFieldText: String = ""
    @State private var isEmptyTextFieldAlertPresented = false
    @State private var isDuplicateTrackerAlertPresented = false
    @State private var isSuccessAlertPresented = false

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
                Alert(title: Text("Invalid input format"), message: Text("Fill least one field"))
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
                Alert(title: Text("Invalid input format"), message: Text("Couldn't use access token and ID tracking identifier at the same time"))
            }
            VStack(alignment: .leading) {
                Text("ACCESS TOKEN:")
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkGray))
                TextField("", text: $accessTokenuserIDTextFieldText, onCommit: {
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
                let userInfo = UserInfo(
                    userID: userIDTextFieldText,
                    idTrackingIdentifier: idTrackerTextFieldText,
                    accessToken: accessTokenuserIDTextFieldText
                )
                RInAppMessaging.registerPreference(userInfo)
                isSuccessAlertPresented = true
            }
            .alert(isPresented: $isSuccessAlertPresented) {
                Alert(title: Text("Saved Successful"))
            }
        }
        .padding(32)
        .onAppear {
            userIDTextFieldText = ""
            idTrackerTextFieldText = ""
            accessTokenuserIDTextFieldText = ""
        }
    }

    private func validateInput() -> Bool {
        let validate = UserInfoHelper.validateInput(
            userID: userIDTextFieldText,
            idTracker: idTrackerTextFieldText,
            token: accessTokenuserIDTextFieldText)

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
