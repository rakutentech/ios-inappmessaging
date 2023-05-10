import SwiftUI

struct SecondView: View {

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Second Page")
            Spacer()
            Text("Tooltip target")
                .frame(width: 120, height: 60)
                .background(Color.orange)
            Spacer()
            Button("Return to home page") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct SecondView_Previews: PreviewProvider {
    static var previews: some View {
        SecondView()
    }
}
