import UIKit
import RInAppMessaging

final class CustomEventViewController: UIViewController {

    @IBOutlet private weak var eventNameTextField: UITextField!
    @IBOutlet private weak var attributesStackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        tabBarItem.accessibilityIdentifier = "tabbar.button.2"
        tabBarController?.tabBar.updateItemIdentifiers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(view.endEditing)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        eventNameTextField.text = nil
        attributesStackView.arrangedSubviews.forEach {
            attributesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func createAttributeStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 24

        let typeTextField = UITextField()
        typeTextField.delegate = self
        typeTextField.borderStyle = .roundedRect

        let nameTextField = UITextField()
        nameTextField.borderStyle = .roundedRect

        let valueTextField = UITextField()
        valueTextField.borderStyle = .roundedRect

        stackView.addArrangedSubview(nameTextField) // name
        stackView.addArrangedSubview(valueTextField) // value
        stackView.addArrangedSubview(typeTextField)

        return stackView
    }

    fileprivate func showAttributeTypeSelection(callback: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Select attribute type", message: nil, preferredStyle: .alert)

        AttributeTypeKeys.allCases.forEach { type in
            let action = UIAlertAction(title: type.rawValue, style: .default) { _ in
                callback(type.rawValue)
            }
            alert.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    private func showInvalidInputError() {
        let alert = UIAlertController(title: "Invalid input format",
                                      message: nil,
                                      preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }

    @IBAction private func addAttributeAction() {
        attributesStackView.addArrangedSubview(createAttributeStackView())
    }

    @IBAction private func sendEventAction() {
        var attributes = [CustomAttribute]()
        for arrangedView in attributesStackView.arrangedSubviews where arrangedView is UIStackView {
            guard let attributeStackView = arrangedView as? UIStackView,
                  attributeStackView.arrangedSubviews.count == 3,
                  let nameTextField = attributeStackView.arrangedSubviews[0] as? UITextField,
                  let valueTextField = attributeStackView.arrangedSubviews[1] as? UITextField,
                  let typeTextField = attributeStackView.arrangedSubviews[2] as? UITextField else {
                assertionFailure("Unexpected view hierarchy")
                return
            }
            guard let customAttribute = EventHelper.customAttributeFromData(name: nameTextField.text ?? "",
                                                                            value: valueTextField.text ?? "",
                                                                            type: typeTextField.text ?? "") else {
                showInvalidInputError()
                return
            }
            attributes.append(customAttribute)
        }

        guard let eventName = eventNameTextField.text, !eventName.isEmpty else {
            showInvalidInputError()
            return
        }

        RInAppMessaging.logEvent(
            CustomEvent(withName: eventName,
                        withCustomAttributes: attributes)
        )
    }
}

extension CustomEventViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        showAttributeTypeSelection { selectedType in
            textField.text = selectedType
        }
        return false
    }
}

enum AttributeTypeKeys: String, CaseIterable, Identifiable {
    case string = "String"
    case boolean = "Boolean"
    case integer = "Integer"
    case double = "Double"
    case date = "Date (ms)"
    case none = ""

    var id: String { self.rawValue }
}
