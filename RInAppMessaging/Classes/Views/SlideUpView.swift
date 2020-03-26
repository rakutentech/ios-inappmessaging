/// SlideUpView for InAppMessaging campaign.
internal class SlideUpView: UIView, SlideUpViewType {

    enum UIConstants {
        static let screenWidth: CGFloat = UIScreen.main.bounds.width // Width of the device.
        static let slideUpHeight: CGFloat = 89 // Height of the banner window.
        static let slideUpLeftPaddingPercentage: CGFloat = 0.07 // Percentage of the left padding to total width.
        static let slideUpRightPaddingPercentage: CGFloat = 0.17 // Percentage of the right padding to total width.
        static let bodyMessageLabelFontSize: CGFloat = 14 // Font size of the message.
        static let bodyMessageLabelHeight: CGFloat = 61 // Height of the UILabel for the body message.
        static let slideUpContentTopPadding: CGFloat = 12 // Top padding for the content inside the slide up view.
        static let exitButtonSize: CGFloat = 20 // Size of the button.
        static let exitButtonRightPadding: CGFloat = 36 // Amount of padding right of the exit button
    }

    var onDismiss: (() -> Void)?
    var isUsingAutoLayout: Bool {
        return false
    }

    private let presenter: SlideUpViewPresenterType
    private let dialogView = UIView()
    private var slideDirection = SlideDirection.bottom
    private var bottomSafeAreaInsets: CGFloat {
        if #available(iOS 11.0, *) {
            let bottomSafeArea = UIApplication.shared.keyWindow!.safeAreaInsets.bottom

            // Lessen the gap from iPhone X and newer phones so that there will be less white space.
            return bottomSafeArea == 0 ? 0 : bottomSafeArea - 20
        }

        return 0
    }

    init(presenter: SlideUpViewPresenterType) {
        self.presenter = presenter
        super.init(frame: UIScreen.main.bounds)
        self.presenter.view = self
        self.presenter.viewDidInitialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(viewModel: SlideUpViewModel) {

        self.slideDirection = viewModel.slideDirection
        frame.origin = startingFramePosition(fromSliding: viewModel.slideDirection)
        frame.size = CGSize(width: UIConstants.screenWidth, height: UIConstants.slideUpHeight + bottomSafeAreaInsets)

        dialogView.accessibilityIdentifier = "dialogView"
        dialogView.backgroundColor = viewModel.backgroundColor
        dialogView.frame = CGRect(x: 0,
                                  y: 0,
                                  width: UIConstants.screenWidth,
                                  height: UIConstants.slideUpHeight + bottomSafeAreaInsets
        )

        if let bodyMessage = viewModel.messageBody {
            appendMessage(bodyMessage, color: viewModel.messageBodyColor)
        }

        appendExitButton()
        appendSubviews()

        presenter.logImpression(type: .impression)
    }

    func animateOnShow() {
        //swiftlint:disable:next todo
        //TODO: (Daniel Tam) - Support TOP direction for slide-up
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            switch self.slideDirection {
            case .bottom:
                self.center.y -= UIConstants.slideUpHeight
            case .left, .right:
                self.center.x = UIConstants.screenWidth / 2
            case .top:
                break
            }

            self.layoutIfNeeded()
        })
    }

    private func appendMessage(_ message: String, color: UIColor) {
        let leftPadding = UIConstants.screenWidth * UIConstants.slideUpLeftPaddingPercentage
        let rightPadding = UIConstants.screenWidth * UIConstants.slideUpRightPaddingPercentage

        let bodyMessageLabel = UILabel(
            frame: CGRect(x: leftPadding,
                          y: UIConstants.slideUpContentTopPadding,
                          width: UIConstants.screenWidth - (leftPadding + rightPadding),
                          height: UIConstants.bodyMessageLabelHeight
            )
        )

        bodyMessageLabel.text = message
        bodyMessageLabel.textColor = color
        bodyMessageLabel.font = .systemFont(ofSize: UIConstants.bodyMessageLabelFontSize)
        bodyMessageLabel.setLineSpacing(lineSpacing: 3.0)
        bodyMessageLabel.textAlignment = .left
        bodyMessageLabel.numberOfLines = 3
        bodyMessageLabel.lineBreakMode = .byTruncatingTail
        bodyMessageLabel.isUserInteractionEnabled = true
        bodyMessageLabel.accessibilityIdentifier = "bodyMessage"
        bodyMessageLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onContentClick)))

        dialogView.addSubview(bodyMessageLabel)
    }

    private func appendExitButton() {
        let exitButton = ExitButton(
            frame: CGRect(x: UIConstants.screenWidth - UIConstants.exitButtonRightPadding,
                          y: UIConstants.slideUpContentTopPadding,
                          width: UIConstants.exitButtonSize,
                          height: UIConstants.exitButtonSize
            )
        )

        exitButton.fontSize = 14.0
        exitButton.invertedColors = false
        exitButton.addTarget(self, action: #selector(onExitButtonClick), for: .touchUpInside)

        dialogView.addSubview(exitButton)
    }

    private func appendSubviews() {
        addSubview(dialogView)
    }

    /// Find the frame origin depending on the slide direction.
    /// - Parameter direction: Direction to slide from.
    /// - Returns: Origin of the campaign frame.
    private func startingFramePosition(fromSliding direction: SlideDirection) -> CGPoint {
        let yPosition = UIScreen.main.bounds.height

        switch direction {
        case .bottom:
            return CGPoint(x: 0, y: yPosition - bottomSafeAreaInsets)
        case .left:
            return CGPoint(x: -UIConstants.screenWidth, y: yPosition - UIConstants.slideUpHeight)
        case .right:
            return CGPoint(x: UIConstants.screenWidth * 2, y: yPosition - UIConstants.slideUpHeight)

        //swiftlint:disable:next todo
        //TODO: Support TOP direction for sliding.
        case .top:
            return .zero
        }
    }

    /// Obj-c selector to handle the action when the onClick content is tapped.
    @objc private func onContentClick() {
        presenter.didClickContent()
    }

    /// Obj-c selector to dismiss the modal view when the 'X' is tapped.
    @objc private func onExitButtonClick() {
        presenter.didClickExitButton()
    }
}
