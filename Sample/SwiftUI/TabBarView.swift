import SwiftUI

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
                CustomEventView().tabItem {
                    Text("Custom Event")
                }
                .accessibility(identifier: "tabbar.button.2")
            }
        }
    }
}

struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
