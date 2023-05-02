import SwiftUI

struct MainView: View {
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
                    
                }
                Button("purchase_successful") {
                    
                }
                Button("login_successful") {
                    
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
            VStack (spacing: 35) {
                Button("Init with Tooltip") {
                    
                }
                Button("Init w/o Tooltip") {
                    
                }
                Button("Open modal page") {
                    
                }
            }
            Spacer().frame(height: 250)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
