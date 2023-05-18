import SwiftUI
import RInAppMessaging

@available(iOS 13.0, *)
struct CustomEventView: View {

    @State private var isAlertPresented = false
    @State private var isErrorAlertPresented = false
    @State private var eventName: String = ""
    /// - Note: Init with one empty attribute for UI purpose
    @State private var attributes = [EventAttribute()]
    @State private var editingTextFieldIndex = 0

    var body: some View {
        ScrollView {
            HStack {
                Text("EVENT NAME: ")
                    .fontWeight(.bold)
                    .opacity(0.75)
                TextField("", text: $eventName)
                    .textFieldStyle(.roundedBorder)
            }.padding(.horizontal, 40)
            Text("Attributes")
                .foregroundColor(.red)
                .font(.system(size: 22))
                .padding()
            HStack(spacing: 10) {
                Group {
                    Text("NAME")
                        .fontWeight(.bold)
                    Text("VALUE")
                        .fontWeight(.bold)
                    Text("TYPE")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .opacity(0.75)
            }.padding(.horizontal, 20)
            ForEach($attributes) { $attribute in
                HStack(spacing: 10) {
                    Group {
                        TextField("", text: $attribute.name)
                        TextField("", text: $attribute.value)
                        TextField("", text: $attribute.type, onEditingChanged: { state in
                            if state {isAlertPresented = true }
                            if let index = attributes.firstIndex(where: {$0.id == attribute.id}) {
                                editingTextFieldIndex = index
                            }
                        })
                        .actionSheet(isPresented: $isAlertPresented) {
                            ActionSheet(
                                title: Text("Select attribute type"),
                                buttons: Array(AttributeTypeKeys.allCases
                                    .map({ type in
                                        if type == .none {
                                            return ActionSheet.Button.cancel(Text("Cancel"))
                                        }
                                        return ActionSheet.Button.default(Text(type.rawValue)) {
                                            attributes[editingTextFieldIndex].type = type.rawValue
                                        }
                                    }))
                            )
                        }
                    }.textFieldStyle(.roundedBorder)
                }.padding(.horizontal, 10)
            }
            HStack {
                Button("Add") {
                    attributes.append(
                        EventAttribute())
                }.padding()
                Spacer()
            }
            Button("SEND") {
                sendEvent()
            }.padding()
            Spacer().frame(height: 400)
        }
        .alert(isPresented: $isErrorAlertPresented, content: {
            Alert(title: Text("Invalid input format"))
        }).onDisappear {
            /// re-init to reset attribute content and filled with one empty attribute for UI purpose
            attributes = [
                EventAttribute()
            ]
            eventName = ""
        }
    }

    private func sendEvent() {
        var eventAttributes = [CustomAttribute]()
        for attribute in self.attributes {
            guard let customAttribute = EventHelper.customAttributeFromData(name: attribute.name,
                                                                            value: attribute.value,
                                                                            type: attribute.type) else {
                isErrorAlertPresented = true
                return
            }
            eventAttributes.append(customAttribute)
        }

        guard !eventName.isEmpty else {
            isErrorAlertPresented = true
            return
        }

        RInAppMessaging.logEvent(
            CustomEvent(withName: eventName,
                        withCustomAttributes: eventAttributes)
        )
    }
}

@available(iOS 13.0, *)
struct CustomEventView_Previews: PreviewProvider {
    static var previews: some View {
        CustomEventView()
    }
}

private struct EventAttribute: Hashable, Identifiable {
    let id = UUID()
    var name: String
    var value: String
    var type: String

    init(name: String = "", value: String = "", type: String = "") {
        self.name = name
        self.value = value
        self.type = type
    }
}
