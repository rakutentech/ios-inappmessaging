import UIKit
import class WebKit.WKWebView

internal enum FullViewMode: Equatable {
    case none
    case modal(maxWindowHeightPercentage: CGFloat)
    case fullScreen
}

/// Base class for full size campaign views.
internal class FullView: UIView, FullViewType, RichContentBrowsable {

    // Constant values used for UI elements in model views.
    struct UIConstants {
        var backgroundColor: UIColor?
        var cornerRadiusForDialogView: CGFloat = 0 // Adjust how round the edge the dialog view will be.
        var headerMessageFontSize: CGFloat = 16 // Font size for the header message.
        var bodyMessageFontSize: CGFloat = 14 // Font size for the body message.
        var bodyMarginTop: CGFloat = 18 // Distance from header (body) to top edge or image
        var buttonHeight: CGFloat = 40 // Define the height to use for the button.
        var buttonsSpacing: CGFloat = 8 // Size of the gap between the buttons when there are two buttons.
        var singleButtonWidthMargin: CGFloat = 24 // Width offset when only one button is given.
        var exitButtonFontSize: CGFloat = 13 // Size of the exit button.
        var exitButtonSize: CGFloat = 15 // Size of the exit button.
        var exitButtonVerticalOffset: CGFloat = 16 // Position of where the button should be relative to the safe area frame.
        var dialogViewHorizontalMargin: CGFloat = 20 // The spacing between dialog view and the children elements.
        var dialogViewWidthOffset: CGFloat = 0 // Spacing on the left and right side of subviews.
        var dialogViewWidthMultiplier: CGFloat = 1 // Spacing on the left and right side of subviews.
    }
    var uiConstants = UIConstants()
    var mode: FullViewMode {
        return .none
    }
    var isOptOutChecked: Bool {
        return !optOutView.isHidden && optOutView.isChecked
    }
    var onDismiss: (() -> Void)?

    private let presenter: FullViewPresenter

    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var contentView: UIView! // Wraps dialog view to allow rounded corners
    @IBOutlet private weak var dialogContainerView: UIView!
    @IBOutlet private weak var dialogView: UIStackView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var lowerBodyLabel: UILabel!
    @IBOutlet private weak var bodyView: UIStackView!
    @IBOutlet private weak var bodyContainerView: UIScrollView!
    @IBOutlet private weak var webViewContainer: UIView!
    // WKWebView cannot be used as a @IBOutlet for targets that support versions older than iOS 11
    @IBOutlet private weak var optOutView: OptOutMessageView!
    @IBOutlet private weak var optOutAndButtonsSpacer: UIView!
    @IBOutlet private weak var buttonsContainer: UIStackView!
    @IBOutlet private(set) weak var exitButton: ExitButton! {
        didSet {
            exitButton.invertedColors = hasImage
            exitButton.addTarget(self, action: #selector(onExitButtonClick), for: .touchUpInside)
        }
    }

    @IBOutlet private weak var contentWidthOffsetConstraint: NSLayoutConstraint!
    /// Constriaint for vertical position above content view
    @IBOutlet private weak var exitButtonYPositionConstraint: NSLayoutConstraint!

    // Will change to true if campaign has an image URL.
    private var hasImage = false {
        didSet {
            exitButton.invertedColors = hasImage
            imageView.isHidden = !hasImage
        }
    }

    init(presenter: FullViewPresenter) {
        self.presenter = presenter
        super.init(frame: .zero)
        self.presenter.view = self
        self.presenter.viewDidInitialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeView(viewModel: FullViewModel) {

        removeAllSubviews()
        guard mode != .none else {
            return
        }

        setupMainView()
        setUpAccessibility()
        updateUIConstants()
        layoutContentView(viewModel: viewModel)
        layoutUIComponents()

        backgroundView.backgroundColor = uiConstants.backgroundColor ?? viewModel.backgroundColor

        if let image = viewModel.image {
            hasImage = true
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
        } else {
            hasImage = false
        }

        createMessageBody(viewModel: viewModel)

        presenter.logImpression(type: .impression)
    }

    func updateUIConstants() { }

    private func setUpAccessibility() {
        backgroundView.accessibilityIdentifier = "IAMBackgroundView"
        dialogView.accessibilityIdentifier = "dialogView"
        bodyView.accessibilityIdentifier = "textView"
        bodyLabel.accessibilityIdentifier = "bodyMessage"
        lowerBodyLabel.accessibilityIdentifier = "lowerBodyMessage"
        headerLabel.accessibilityIdentifier = "headerMessage"
    }

    private func setupMainView() {
        let nib = UINib(nibName: "FullView", bundle: Bundle.sdk)
        guard let containerView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            assertionFailure("Couldn't load view from FullView.xib")
            return
        }
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        containerView.activateConstraintsFilling(parent: self)
    }

    private func layoutContentView(viewModel: FullViewModel) {
        layoutMargins = .zero
        backgroundColor = .clear

        switch mode {
        case .fullScreen:
            let layoutGuide: UILayoutGuide
            if #available(iOS 11.0, *) {
                layoutGuide = safeAreaLayoutGuide
            } else {
                layoutGuide = layoutMarginsGuide
            }
            contentView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
            contentView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
        case .modal(let maxWindowHeightPercentage):
            contentView.heightAnchor.constraint(lessThanOrEqualTo: backgroundView.heightAnchor,
                                                multiplier: maxWindowHeightPercentage).isActive = true
        default:
            assertionFailure("Unsupported mode")
        }

        contentWidthOffsetConstraint.constant = -uiConstants.dialogViewWidthOffset
        contentWidthOffsetConstraint.setMultiplier(uiConstants.dialogViewWidthMultiplier)

        contentView.backgroundColor = viewModel.backgroundColor
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = uiConstants.cornerRadiusForDialogView
    }

    private func layoutUIComponents() {
        dialogView.isLayoutMarginsRelativeArrangement = true
        dialogView.layoutMargins = UIEdgeInsets(top: 0, left: uiConstants.dialogViewHorizontalMargin,
                                                bottom: 0, right: uiConstants.dialogViewHorizontalMargin)

        exitButton.widthAnchor.constraint(equalToConstant: uiConstants.exitButtonSize).isActive = true
        exitButton.heightAnchor.constraint(equalToConstant: uiConstants.exitButtonSize).isActive = true
        exitButtonYPositionConstraint.constant = uiConstants.exitButtonVerticalOffset
        exitButton.fontSize = uiConstants.exitButtonFontSize
    }

    /// Creates the modal view to be displayed using the campaign information.
    /// - Parameter viewModel: The view's view model.
    private func createMessageBody(viewModel: FullViewModel) {
        bodyView.isLayoutMarginsRelativeArrangement = true
        bodyView.layoutMargins.top = uiConstants.bodyMarginTop

        if viewModel.isHTML, let messageBody = viewModel.messageBody {
            hasImage = false
            exitButton.invertedColors = true
            bodyContainerView.isHidden = true
            setupWebView(withHtmlString: messageBody)
        } else {
            if let headerMessage = viewModel.header {
                setupHeaderMessage(headerMessage, color: viewModel.headerColor)
            }
            setupBodyMessage(viewModel: viewModel)
        }

        optOutView.isHidden = !viewModel.showOptOut

        presenter.loadButtons()
        updateUIComponentsVisibility(viewModel: viewModel)
    }

    private func updateUIComponentsVisibility(viewModel: FullViewModel) {
        let isBodyEmpty = (viewModel.isHTML ||
                            viewModel.header?.isEmpty != false &&
                            viewModel.messageBody?.isEmpty != false &&
                            viewModel.messageLowerBody?.isEmpty != false) &&
                        !viewModel.showOptOut &&
                        !viewModel.showButtons

        optOutAndButtonsSpacer.isHidden = buttonsContainer.isHidden || optOutView.isHidden
        dialogContainerView.isHidden = isBodyEmpty
    }

    /// Creates a webview and load in the HTML string provided by the Ping response.
    /// - Parameter htmlString: HTML string by the backend. This string should
    /// contain only safe characters -- it should NOT contain any un-escaped characters.
    private func setupWebView(withHtmlString htmlString: String) {
        let webView = createWebView(withHtmlString: htmlString,
                                    andFrame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false

        webViewContainer.isHidden = false
        webViewContainer.removeAllSubviews()
        webViewContainer.addSubview(webView)
        webView.activateConstraintsFilling(parent: webViewContainer)
    }

    /// Creates the text view to be displayed using the campaign information.
    /// - Parameter viewModel: The view's view model.
    private func setupBodyMessage(viewModel: FullViewModel) {
        if let bodyMessage = viewModel.messageBody {
            bodyLabel.isHidden = false
            bodyLabel.text = bodyMessage
            bodyLabel.textColor = viewModel.messageBodyColor
            bodyLabel.setLineSpacing(lineSpacing: 3.0)
            bodyLabel.font = .systemFont(ofSize: uiConstants.bodyMessageFontSize)
            bodyLabel.textAlignment = .left
            bodyLabel.lineBreakMode = .byWordWrapping
            bodyLabel.numberOfLines = 0
        } else {
            bodyLabel.isHidden = true
        }

        if let lowerBodyMessage = viewModel.messageLowerBody {
            lowerBodyLabel.isHidden = false
            lowerBodyLabel.text = lowerBodyMessage
            lowerBodyLabel.textColor = viewModel.messageBodyColor
            lowerBodyLabel.setLineSpacing(lineSpacing: 3.0)
            lowerBodyLabel.font = .systemFont(ofSize: uiConstants.bodyMessageFontSize)
            lowerBodyLabel.textAlignment = .left
            lowerBodyLabel.lineBreakMode = .byWordWrapping
            lowerBodyLabel.numberOfLines = 0
        } else {
            lowerBodyLabel.isHidden = true
        }
    }

    private func setupHeaderMessage(_ headerMessage: String, color: UIColor) {
        headerLabel.text = headerMessage
        headerLabel.textColor = color
        headerLabel.setLineSpacing(lineSpacing: 3.0)
        headerLabel.textAlignment = .center
        headerLabel.lineBreakMode = .byWordWrapping
        headerLabel.numberOfLines = 0
        headerLabel.font = .boldSystemFont(ofSize: uiConstants.headerMessageFontSize)
    }

    /// Adds buttons to dialog view.
    /// - Parameter buttons: A list of tuples containing `ActionButton` and its view model.
    func addButtons(_ buttons: [(ActionButton, viewModel: ActionButtonViewModel)]) {
        guard !buttons.isEmpty else {
            buttonsContainer.isHidden = true
            return
        }

        buttonsContainer.isHidden = false
        buttonsContainer.arrangedSubviews.forEach { buttonsContainer.removeArrangedSubview($0) }

        let onlyOneButton = buttons.count == 1
        let margin = onlyOneButton ? uiConstants.singleButtonWidthMargin : 0
        buttonsContainer.isHidden = false
        buttonsContainer.spacing = uiConstants.buttonsSpacing
        buttonsContainer.isLayoutMarginsRelativeArrangement = true
        buttonsContainer.layoutMargins = UIEdgeInsets(top: 0, left: margin,
                                                      bottom: 0, right: margin)

        for (index, (button, viewModel)) in buttons.enumerated() {
            button.setup(viewModel: viewModel)
            button.accessibilityIdentifier = "Button\(index)"

            button.addTarget(self, action: #selector(onActionButtonClick), for: .touchUpInside)

            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: uiConstants.buttonHeight).isActive = true
            buttonsContainer.addArrangedSubview(button)
        }
    }

    /// Obj-c selector to handle close, redirect, and deeplink type buttons.
    /// When the URL fails to validate through canOpenUrl() or is empty, an alert message will pop up
    /// to warn about the navigation error.
    /// - Parameter sender: The button that was clicked.
    @objc private func onActionButtonClick(_ sender: ActionButton) {
        presenter.didClickAction(sender: sender)
    }

    /// Obj-c selector to handle exit button.
    @objc private func onExitButtonClick() {
        presenter.didClickExitButton()
    }
}
