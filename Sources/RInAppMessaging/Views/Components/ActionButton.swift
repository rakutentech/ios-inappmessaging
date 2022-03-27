import UIKit
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif

// Button object used in campaigns's message view.
internal class ActionButton: UIButton {

    private enum Constants {
        static let fontSize: CGFloat = 14
        static let minFontSize: CGFloat = 10
        static let labelMargin = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
        static let borderColor = UIColor(hexString: "#D1D1D1")!
    }

    let impression: ImpressionType
    let uri: String?
    let trigger: Trigger?

    private let textLabel = UILabel()

    init(impression: ImpressionType, uri: String?, trigger: Trigger?) {
        self.impression = impression
        self.uri = uri
        self.trigger = trigger

        super.init(frame: .zero)
        addLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(viewModel: ActionButtonViewModel) {
        textLabel.text = viewModel.text
        textLabel.font = .iamButton(ofSize: Constants.fontSize)
        textLabel.textColor = viewModel.textColor
        textLabel.numberOfLines = 2
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.textAlignment = .center
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = Constants.minFontSize/Constants.fontSize

        layer.cornerRadius = Constants.cornerRadius
        self.backgroundColor = viewModel.backgroundColor
        layer.borderColor = Constants.borderColor.cgColor
        layer.borderWidth = viewModel.shouldDrawBorder ? Constants.borderWidth : 0
    }

    private func addLabel() {
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.leftAnchor.constraint(equalTo: leftAnchor,
                                            constant: Constants.labelMargin.left),
            textLabel.rightAnchor.constraint(equalTo: rightAnchor,
                                             constant: -Constants.labelMargin.right),
            textLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor,
                                           constant: Constants.labelMargin.top),
            textLabel.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor,
                                              constant: -Constants.labelMargin.bottom),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
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
