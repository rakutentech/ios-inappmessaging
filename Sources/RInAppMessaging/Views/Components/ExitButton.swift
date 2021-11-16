import UIKit

/// The 'X' button used to close campaign's message.
internal class ExitButton: UIControl {

//    private let xLabel = UILabel()
    private var exitImageView = UIImageView()

    var invertedColors = false {
        didSet {
            updateColors()
        }
    }
    var fontSize: CGFloat = UIFont.systemFontSize {
        didSet {
//            xLabel.font = .systemFont(ofSize: fontSize)
        }
    }

//    override func layoutSubviews() {
//        super.layoutSubviews()
//        layer.cornerRadius = frame.width / 2
//    }

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
//        xLabel.textAlignment = .center
//        xLabel.layer.masksToBounds = true
//        xLabel.accessibilityIdentifier = "exitButton"
//        xLabel.accessibilityTraits = .button

//        fontSize = UIFont.systemFontSize
//        layer.masksToBounds = true
        updateColors()

//        xLabel.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(xLabel)
//        xLabel.constraintsFilling(parent: self, activate: true)
        

        exitImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(exitImageView)
        exitImageView.constraintsFilling(parent: self, activate: true)
    }

    private func updateColors() {
//        xLabel.backgroundColor = invertedColors ? .white : .black
//        xLabel.textColor = invertedColors ? .black : .white
        
        let imageName = invertedColors ? "Exit-Dark" : "Exit-Light"
        let insetValue: CGFloat = -14
        let insets = UIEdgeInsets(top: insetValue, left: insetValue, bottom: insetValue, right: insetValue)
        exitImageView.image = UIImage(named: imageName, in: .sdkAssets, compatibleWith: nil)!
            .withAlignmentRectInsets(insets)
    }
}
