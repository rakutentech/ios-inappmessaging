import SwiftUI
@testable import RInAppMessaging

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
                Button("Init w/o Tooltip") {
                    initSDK(enableTooltipFeature: false)
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
        .alert(isPresented: $isErrorAlertPresented) {
            Alert(title: Text("Error"), message: Text("IAM SDK is already initialized"))
        }
        .alert(isPresented: $isErrorAlertPresented) {
            Alert(title: Text("Init successful"))
        }
    }

    private func initSDK(enableTooltipFeature: Bool) {
        guard RInAppMessaging.initializedModule == nil else {
            isErrorAlertPresented = true
            return
        }
        RInAppMessaging.configure(enableTooltipFeature: enableTooltipFeature)
        isOnFinishedAlertPresented = true
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
