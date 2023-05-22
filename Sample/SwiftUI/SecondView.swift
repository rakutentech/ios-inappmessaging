import SwiftUI
import RInAppMessaging

@available(iOS 13.0, *)
struct SecondView: View {

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Second Page")
            Spacer()
                if #available(iOS 15.0, *) {
                    ZStack {
                        tooltipTarget(identifier: "tooltip.test.1")
                        tooltipTarget(identifier: "tooltip.test.2")
                        tooltipTarget(identifier: "tooltip.test.3")
                        tooltipTarget(identifier: "tooltip.test.4")
                        tooltipTarget(identifier: "tooltip.test.5")
                        tooltipTarget(identifier: "tooltip.test.6")
                        tooltipTarget(identifier: "tooltip.test.7")
                        tooltipTarget(identifier: "tooltip.test.8")
                    }
                } else {
                    Text("SwiftUI Tooltip requires iOS 15+")
                        .frame(width: 120, height: 60)
                        .background(Color.orange)
                }
            Spacer()
            Button("Return to home page") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @available(iOS 15.0, *)
    @ViewBuilder private func tooltipTarget(identifier: String) -> some View {
        Text("Tooltip target")
            .frame(width: 120, height: 60)
            .background(Color.orange)
            .canHaveTooltip(identifier: identifier)
    }
}

@available(iOS 13.0, *)
struct SecondView_Previews: PreviewProvider {
    static var previews: some View {
        SecondView()
    }
}
