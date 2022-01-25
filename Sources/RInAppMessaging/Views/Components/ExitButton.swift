import UIKit

/// The 'X' button used to close campaign's message.
internal class ExitButton: UIControl {

    private lazy var exitImageView: UIImageView = {
        let exitImageView = UIImageView(image: coordinatedExitIcon)
        exitImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(exitImageView)
        exitImageView.constraintsFilling(parent: self, activate: true)
        return exitImageView
    }()

    var invertedColors = false {
        didSet {
            _ = exitImageView
        }
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        accessibilityIdentifier = "exitButton"
        accessibilityTraits = .button
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
    }

    /// If invertedColors, show dark icon
    private var coordinatedExitIcon: UIImage {
        let insetValue: CGFloat = -14
        let insets = UIEdgeInsets(top: insetValue, left: insetValue, bottom: insetValue, right: insetValue)
        let imageName = invertedColors ? "Exit-Dark" : "Exit-Light"
        return UIImage(named: imageName, in: .sdkAssets, compatibleWith: nil)!.withAlignmentRectInsets(insets)
    }
}
