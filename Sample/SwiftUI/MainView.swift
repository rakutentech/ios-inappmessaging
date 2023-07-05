import SwiftUI
@testable import RInAppMessaging

@available(iOS 13.0, *)
struct MainView: View {

    @State private var isErrorAlertPresented = false
    @State private var isOnFinishedAlertPresented = false
    @State private var isPresentSecondView = false

    var body: some View {
        ScrollView {
            Text("EVENTS")
                .fontWeight(.bold)
                .foregroundColor(.black)
                .opacity(0.75)
            Divider()
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
            VStack(spacing: 35) {
                Button("app_launch") {
                    RInAppMessaging.logEvent(AppStartEvent())
                }
                Button("purchase_successful") {
                    let purchaseEvent = PurchaseSuccessfulEvent()
                    _ = purchaseEvent.setPurchaseAmount(50)
                    _ = purchaseEvent.setItemList(["box", "hammer"])
                    _ = purchaseEvent.setCurrencyCode("USD")
                    _ = purchaseEvent.setNumberOfItems(2)

                    RInAppMessaging.logEvent(purchaseEvent)
                }
                Button("login_successful") {
                    RInAppMessaging.logEvent(LoginSuccessfulEvent())
                }
            }
            Spacer().frame(height: 40)
            Text("ACTIONS")
                .fontWeight(.bold)
                .foregroundColor(.black)
                .opacity(0.75)
            Divider()
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
            VStack(spacing: 35) {
                Button("Init with Tooltip") {
                    initSDK(enableTooltipFeature: true)
                }
                .alert(isPresented: $isErrorAlertPresented) {
                    Alert(title: Text("alert_title_error".localized), message: Text("alert_message_already_initialized".localized))
                }
                Button("Init w/o Tooltip") {
                    initSDK(enableTooltipFeature: false)
                }
                .alert(isPresented: $isOnFinishedAlertPresented) {
                    Alert(title: Text("alert_message_init_successful".localized))
                }
                Button("Open modal page") {
                    isPresentSecondView = true
                }
            }
            Spacer().frame(height: 250)
        }
        .sheet(isPresented: $isPresentSecondView, content: {
            SecondView()
        })
    }

    private func initSDK(enableTooltipFeature: Bool) {
        guard RInAppMessaging.initializedModule == nil else {
            isErrorAlertPresented = true
            return
        }
        RInAppMessaging.configure(enableTooltipFeature: enableTooltipFeature)
        RInAppMessaging.registerPreference(UserInfoHelper.sharedPreference)
        isOnFinishedAlertPresented = true
    }
}

@available(iOS 13.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
