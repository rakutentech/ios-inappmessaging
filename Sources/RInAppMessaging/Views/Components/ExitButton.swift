import UIKit

/// The 'X' button used to close campaign's message.
internal class ExitButton: UIControl {

    private var exitImageView = UIImageView()

    var invertedColors = false {
        didSet {
            updateColors()
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
        exitImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(exitImageView)
        exitImageView.constraintsFilling(parent: self, activate: true)
    }

    /// If invertedColors, show dark icon
    private func updateColors() {
        let insetValue: CGFloat = -14
        let insets = UIEdgeInsets(top: insetValue, left: insetValue, bottom: insetValue, right: insetValue)
        let imageName = invertedColors ? "Exit-Dark" : "Exit-Light"
        exitImageView.image = UIImage(named: imageName, in: .sdkAssets, compatibleWith: nil)!.withAlignmentRectInsets(insets)
    }
}
