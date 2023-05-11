import SwiftUI
import RInAppMessaging

@available(iOS 13.0, *)
struct CustomEventView: View {

    @State private var isAlertPresented = false
    @State private var isErrorAlertPresented = false
    @State private var eventName: String = ""
    /// Init with one empty attribute for UI purpose
    @State private var attributes: [EventAttribute] = [EventAttribute()]
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
                        TextField("", text: $attribute.type.text, onEditingChanged: { state in
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
                                        return ActionSheet.Button.default(Text(type.text)) {
                                            attributes[editingTextFieldIndex].type = type
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
            /// re-init to resent attribute content and filled with one empty attribute for UI purpose
            attributes = [
                EventAttribute()
            ]
            eventName = ""
        }
    }

    private func sendEvent() {
        var attributes = [CustomAttribute]()
        for attribute in self.attributes {
            guard let customAttribute = customAttributeFromData(name: attribute.name,
                                                                value: attribute.value,
                                                                type: attribute.type.text) else {
                isErrorAlertPresented = true
                return
            }
            attributes.append(customAttribute)
        }

        guard !eventName.isEmpty else {
            isErrorAlertPresented = true
            return
        }

        RInAppMessaging.logEvent(
            CustomEvent(withName: eventName,
                        withCustomAttributes: attributes)
        )
    }

    private func customAttributeFromData(name: String, value: String, type: String) -> CustomAttribute? {
        guard !name.isEmpty && !value.isEmpty && !type.isEmpty else {
            return nil
        }

        switch type {
        case AttributeTypeKeys.string.rawValue:
            return CustomAttribute(withKeyName: name,
                                   withStringValue: value as String)

        case AttributeTypeKeys.boolean.rawValue where value.hasBoolValue:
            return CustomAttribute(withKeyName: name,
                                   withBoolValue: value.boolValue)

        case AttributeTypeKeys.integer.rawValue where value.hasIntegerValue:
            return CustomAttribute(withKeyName: name,
                                   withIntValue: value.integerValue)

        case AttributeTypeKeys.double.rawValue where value.hasDoubleValue:
            return CustomAttribute(withKeyName: name,
                                   withDoubleValue: value.doubleValue)

        case AttributeTypeKeys.date.rawValue where value.hasIntegerValue:
            return CustomAttribute(withKeyName: name,
                                   withTimeInMilliValue: value.integerValue)

        default:
            return nil
        }
    }
}

@available(iOS 13.0, *)
struct CustomEventView_Previews: PreviewProvider {
    static var previews: some View {
        CustomEventView()
    }
}

struct EventAttribute: Hashable, Identifiable {
    init(name: String = "", value: String = "", type: AttributeTypeKeys = .none) {
        self.name = name
        self.value = value
        self.type = type
    }

    let id = UUID()
    var name: String
    var value: String
    var type: AttributeTypeKeys
}
