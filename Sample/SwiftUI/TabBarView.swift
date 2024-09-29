import SwiftUI

@available(iOS 14.0, *)
struct TabBarView: View {
    var body: some View {
        VStack {
            Image("IAM")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .padding(.horizontal)
            TabView {
                MainView().tabItem {
                    Text("Main")
                }
                .accessibility(identifier: "tabbar.button.1")
                .canHaveTooltipIfAvailable(identifier: "tabbar.button.1")
                CustomEventView().tabItem {
                    Text("Custom Event")
                }
                .accessibility(identifier: "tabbar.button.2")
                .canHaveTooltipIfAvailable(identifier: "tabbar.button.2")
                UserInfoView().tabItem {
                    Text("User Info")
                }
                .accessibility(identifier: "tabbar.button.3")
                .canHaveTooltipIfAvailable(identifier: "tabbar.button.3")
            }
        }
    }
}

@available(iOS 14.0, *)
struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}

@available(iOS 14.0, *)
extension View {
    func canHaveTooltipIfAvailable(identifier: String) -> some View {
        if #available(iOS 15.0, *) {
            return canHaveTooltip(identifier: identifier)
        } else {
            return self
        }
    }
}
