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
                CustomEventView().tabItem {
                    Text("Custom Event")
                }
            }
        }
    }
}

struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
