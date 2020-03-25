import UIKit

// Button object used in campaigns's message view.
internal class ActionButton: UIButton {

    private enum Constants {
        static let fontSize: CGFloat = 14
        static let cornerRadius: CGFloat = 4
        static let borderWidth: CGFloat = 1
    }

    let impression: ImpressionType
    let uri: String?
    let trigger: Trigger?

    init(impression: ImpressionType, uri: String?, trigger: Trigger?) {
        self.impression = impression
        self.uri = uri
        self.trigger = trigger

        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(viewModel: ActionButtonViewModel) {

        setTitle(viewModel.text, for: .normal)
        setTitleColor(viewModel.textColor, for: .normal)
        titleLabel?.font = .boldSystemFont(ofSize: Constants.fontSize)
        layer.cornerRadius = Constants.cornerRadius
        self.backgroundColor = viewModel.backgroundColor
        layer.borderColor = viewModel.textColor.cgColor
        layer.borderWidth = Constants.borderWidth
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ActionButton else {
            return false
        }

        return object.impression == impression &&
            object.trigger == trigger &&
            object.uri == uri
    }
}
