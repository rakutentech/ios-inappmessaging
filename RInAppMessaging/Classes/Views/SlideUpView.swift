import UIKit

/// SlideUpView for InAppMessaging campaign.
internal class SlideUpView: UIView, SlideUpViewType {

    enum UIConstants {
        static let bodyMessageLabelFontSize: CGFloat = 14
        static let exitButtonSize: CGFloat = 20
        static let exitButtonTopMargin: CGFloat = 12
        static let exitButtonRightMargin: CGFloat = 16
        static let exitButtonTouchAreaSize: CGFloat = 44
        static let slideAnimationDuration: TimeInterval = 0.4
        static var messageBodyPadding: UIEdgeInsets {
            let bottomSafeArea = UIApplication.shared.getKeyWindow()?.safeAreaInsets.bottom ?? CGFloat(0)

            return UIEdgeInsets(top: 16,
                                left: 24,
                                bottom: 12 + bottomSafeArea,
                                right: 16 + exitButtonRightMargin + exitButtonSize)
        }
    }

    static var viewIdentifier: String {
        return "IAMView-SlideUp"
    }

    var onDismiss: ((_ cancelled: Bool) -> Void)?
    var basePresenter: BaseViewPresenterType {
        return presenter
    }

    private let presenter: SlideUpViewPresenterType
    private let dialogView = UIView()
    private var exitButton: ExitButton?
    private var slideFromDirection = SlideDirection.bottom
    private var bottomConstraint: NSLayoutConstraint!
    private var leftConstraint: NSLayoutConstraint!
    private var rightConstraint: NSLayoutConstraint!

    init(presenter: SlideUpViewPresenterType) {
        self.presenter = presenter
        super.init(frame: UIScreen.main.bounds)
        self.presenter.view = self
        self.presenter.viewDidInitialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isTouchInside(touchPoint: point, from: self, targetView: exitButton, touchAreaSize: UIConstants.exitButtonTouchAreaSize) {
            return exitButton
        }
        return super.hitTest(point, with: event)
    }

    func setup(viewModel: SlideUpViewModel) {

        self.slideFromDirection = viewModel.slideFromDirection
        backgroundColor = viewModel.backgroundColor

        setupDialogView()
        setupMessageBody(viewModel.messageBody, color: viewModel.messageBodyColor)
        setupExitButton()

        presenter.logImpression(type: .impression)
    }

    func animateOnShow(completion: @escaping () -> Void) {
        guard [leftConstraint, bottomConstraint, rightConstraint].allSatisfy({ $0 != nil }) else {
            Logger.debug("Error: Constraints not set up. Cancelling animation")
            assertionFailure()
            completion()
            return
        }

        // swiftlint:disable:next todo
        // TODO: (Daniel Tam) - Support TOP direction for slide-up
        switch self.slideFromDirection {
        case .bottom:
            bottomConstraint.constant = -frame.height
        case .left:
            leftConstraint.constant = -frame.width
            rightConstraint.constant = frame.width
        case .right:
            leftConstraint.constant = frame.width
            rightConstraint.constant = -frame.width
        case .top:
            break
        }

        self.superview?.layoutIfNeeded()

        UIView.animate(withDuration: UIConstants.slideAnimationDuration, animations: {
            self.leftConstraint.constant = 0
            self.rightConstraint.constant = 0
            self.bottomConstraint.constant = 0

            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            completion()
        })
    }

    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint] {
        leftConstraint = leftAnchor.constraint(equalTo: parent.leftAnchor)
        rightConstraint = parent.rightAnchor.constraint(equalTo: rightAnchor)
        bottomConstraint = parent.bottomAnchor.constraint(equalTo: bottomAnchor)

        return [leftConstraint, bottomConstraint, rightConstraint]
    }

    private func setupDialogView() {
        dialogView.accessibilityIdentifier = "dialogView-SlideUp"
        dialogView.backgroundColor = .clear
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dialogView)
        dialogView.constraintsFilling(parent: self, activate: true)
    }

    private func setupMessageBody(_ message: String, color: UIColor) {
        let bodyMessageLabel = UILabel()

        bodyMessageLabel.text = message
        bodyMessageLabel.textColor = color
        bodyMessageLabel.font = .systemFont(ofSize: UIConstants.bodyMessageLabelFontSize)
        bodyMessageLabel.setLineSpacing(lineSpacing: 3.0)
        bodyMessageLabel.numberOfLines = 0
        bodyMessageLabel.lineBreakMode = .byWordWrapping
        bodyMessageLabel.isUserInteractionEnabled = true
        bodyMessageLabel.accessibilityIdentifier = "bodyMessage"
        bodyMessageLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                     action: #selector(onContentClick)))

        bodyMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        dialogView.addSubview(bodyMessageLabel)
        NSLayoutConstraint.activate([
            bodyMessageLabel.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor,
                                                       constant: -UIConstants.messageBodyPadding.right),
            bodyMessageLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor,
                                                      constant: UIConstants.messageBodyPadding.left),
            bodyMessageLabel.topAnchor.constraint(equalTo: dialogView.topAnchor,
                                                  constant: UIConstants.messageBodyPadding.top),
            bodyMessageLabel.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor,
                                                    constant: -UIConstants.messageBodyPadding.bottom)
        ])
    }

    private func setupExitButton() {
        let exitButton = ExitButton()

        exitButton.fontSize = 14.0
        exitButton.invertedColors = false
        exitButton.addTarget(self, action: #selector(onExitButtonClick), for: .touchUpInside)

        exitButton.translatesAutoresizingMaskIntoConstraints = false
        self.exitButton = exitButton
        dialogView.addSubview(exitButton)
        NSLayoutConstraint.activate([
            exitButton.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor,
                                                 constant: -UIConstants.exitButtonRightMargin),
            exitButton.topAnchor.constraint(equalTo: dialogView.topAnchor,
                                            constant: UIConstants.exitButtonTopMargin),
            exitButton.widthAnchor.constraint(equalToConstant: UIConstants.exitButtonSize),
            exitButton.heightAnchor.constraint(equalToConstant: UIConstants.exitButtonSize)
        ])
    }

    @objc private func onContentClick() {
        presenter.didClickContent()
    }

    @objc private func onExitButtonClick() {
        presenter.didClickExitButton()
    }
}
