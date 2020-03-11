import UIKit

/// The 'X' button used to close campaign's message.
internal class ExitButton: UIControl {

    private let xLabel = UILabel()

    var invertedColors = false {
        didSet {
            updateColors()
        }
    }
    var fontSize: CGFloat = UIFont.systemFontSize {
        didSet {
            xLabel.font = .systemFont(ofSize: fontSize)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
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
        xLabel.text = "X"
        xLabel.textAlignment = .center
        xLabel.layer.masksToBounds = true
        xLabel.accessibilityIdentifier = "exitButton"
        xLabel.accessibilityTraits = .button

        fontSize = UIFont.systemFontSize
        layer.masksToBounds = true
        updateColors()

        xLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(xLabel)
        xLabel.activateConstraintsFilling(parent: self)
    }

    private func updateColors() {
        xLabel.backgroundColor = invertedColors ? .white : .black
        xLabel.textColor = invertedColors ? .black : .white
    }
}
