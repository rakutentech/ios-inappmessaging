import UIKit
import class WebKit.WKWebView

/// Base class for full size campaign views. (abstract)
internal class FullView: UIView, FullViewType, RichContentBrowsable {

    class var viewIdentifier: String {
        assertionFailure("Subclasses must override this variable")
        return ""
    }

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
        var exitButtonTouchAreaSize: CGFloat = 44 // Clickable area of exit button used in hitTest
        var dialogViewHorizontalMargin: CGFloat = 20 // The spacing between dialog view and the children elements.
        var dialogViewWidthOffset: CGFloat = 0 // Spacing on the left and right side of subviews.
        var dialogViewWidthMultiplier: CGFloat = 1 // Spacing on the left and right side of subviews.
        var bodyViewSafeAreaOffsetY: CGFloat = 0 // Offset for text content applied when there is no image
    }

    internal enum Mode: Equatable {
        case none
        case modal(maxWindowHeightPercentage: CGFloat)
        case fullScreen
    }

    internal enum Layout: String {
        case html
        case textOnly
        case imageOnly
        case textAndImage
    }

    @IBOutlet private(set) weak var contentView: UIView! // Wraps dialog view to allow rounded corners
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var controlsView: UIStackView!
    @IBOutlet private weak var dialogView: UIStackView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var lowerBodyLabel: UILabel!
    @IBOutlet private weak var bodyView: UIStackView!
    @IBOutlet private weak var bodyContainerView: UIView!
    // WKWebView cannot be used as a @IBOutlet for targets that support versions older than iOS 11
    @IBOutlet private weak var webViewContainer: UIView!
    @IBOutlet private weak var optOutView: OptOutMessageView!
    @IBOutlet private weak var optOutAndButtonsSpacer: UIView!
    @IBOutlet private weak var buttonsContainer: UIStackView!
    @IBOutlet private weak var contentScrollView: UIScrollView!
    @IBOutlet private(set) weak var exitButton: ExitButton! {
        didSet {
            exitButton.invertedColors = hasImage
            exitButton.addTarget(self, action: #selector(onExitButtonClick), for: .touchUpInside)
        }
    }

    @IBOutlet private weak var contentWidthOffsetConstraint: NSLayoutConstraint!
    /// Constriaint for vertical position above content view
    @IBOutlet private weak var exitButtonYPositionConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bodyViewOffsetYConstraint: NSLayoutConstraint!

    private let presenter: FullViewPresenterType

    var uiConstants = UIConstants()
    var mode: Mode {
        return .none
    }
    var isOptOutChecked: Bool {
        return !optOutView.isHidden && optOutView.isChecked
    }
    var onDismiss: ((_ cancelled: Bool) -> Void)?
    var basePresenter: BaseViewPresenterType {
        return presenter
    }

    private var layout: Layout?
    private(set) var hasImage = false {
        didSet {
            exitButton.invertedColors = hasImage
            imageView.isHidden = !hasImage
            
            if hasImage {
                let high  = UIView()
                high.backgroundColor = .yellow.withAlphaComponent(0.5)
                
                addSubview(high)
                high.translatesAutoresizingMaskIntoConstraints = false
                high.centerXAnchor.constraint(equalTo: exitButton.centerXAnchor).isActive = true
                high.centerYAnchor.constraint(equalTo: exitButton.centerYAnchor).isActive = true
                high.widthAnchor.constraint(equalToConstant: exitButton.bounds.width).isActive = true
                high.heightAnchor.constraint(equalToConstant: exitButton.bounds.height).isActive = true
            }
        }
    }

    init(presenter: FullViewPresenterType) {
        self.presenter = presenter
        super.init(frame: .zero)
        self.presenter.view = self
        self.presenter.viewDidInitialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateUIConstants()
        exitButtonYPositionConstraint.constant = uiConstants.exitButtonVerticalOffset
        bodyViewOffsetYConstraint.constant = hasImage ? 0 : uiConstants.bodyViewSafeAreaOffsetY

        DispatchQueue.main.async { [self] in
            // Fixes a problem with content size width being set 0.5pt too much
            // (landscape iPad), resulting in horizontal scroll bouncing.
            contentScrollView.contentSize.width = contentScrollView.bounds.width
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isTouchInside(touchPoint: point, from: self, targetView: exitButton, touchAreaSize: uiConstants.exitButtonTouchAreaSize) {
            return exitButton
        }
        return super.hitTest(point, with: event)
    }

    func setup(viewModel: FullViewModel) {
        removeAllSubviews()

        guard mode != .none else {
            return
        }

        setupMainView()

        if let image = viewModel.image {
            hasImage = true
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
        } else {
            hasImage = false
        }

        if viewModel.isHTML {
            layout = .html
        } else if hasImage {
            layout = viewModel.hasText ? .textAndImage : .imageOnly
        } else if viewModel.hasText {
            layout = .textOnly
        }

        setupAccessibility()
        updateUIConstants()

        backgroundView.backgroundColor = uiConstants.backgroundColor ?? viewModel.backgroundColor

        layoutContentView(viewModel: viewModel)
        layoutUIComponents()

        createMessageBody(viewModel: viewModel)

        presenter.logImpression(type: .impression)
    }

    func updateUIConstants() { }

    func animateOnShow(completion: @escaping () -> Void) { completion() }

    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint] {
        return constraintsFilling(parent: parent, activate: false)
    }

    private func setupAccessibility() {
        var displayMode = ""
        switch mode {
        case .fullScreen:
            displayMode = "FullScreen"
        case .modal:
            displayMode = "Modal"
        default: ()
        }

        backgroundView.accessibilityIdentifier = "backgroundView"
        dialogView.accessibilityIdentifier = "dialogView-" + displayMode
        bodyView.accessibilityIdentifier = "textView"
        bodyLabel.accessibilityIdentifier = "bodyMessage"
        lowerBodyLabel.accessibilityIdentifier = "lowerBodyMessage"
        headerLabel.accessibilityIdentifier = "headerMessage"
        imageView.accessibilityIdentifier = "imageView"
        imageView.isAccessibilityElement = true

        if let layout = layout {
            accessibilityIdentifier = type(of: self).viewIdentifier + " data-qa=\"\(layout)\""
        }
    }

    private func setupMainView() {
        let nib = UINib(nibName: "FullView", bundle: Bundle.sdkAssets)
        guard let containerView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            assertionFailure("Couldn't load view from FullView.xib")
            return
        }
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        containerView.constraintsFilling(parent: self, activate: true)
    }

    private func layoutContentView(viewModel: FullViewModel) {
        layoutMargins = .zero
        backgroundColor = .clear

        switch mode {
        case .fullScreen:
            contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
        case .modal(let maxWindowHeightPercentage):
            contentView.heightAnchor.constraint(lessThanOrEqualTo: backgroundView.heightAnchor,
                                                multiplier: maxWindowHeightPercentage).isActive = true
        default:
            assertionFailure("Unsupported mode")
        }

        contentWidthOffsetConstraint.constant = -uiConstants.dialogViewWidthOffset
        contentWidthOffsetConstraint.setMultiplier(uiConstants.dialogViewWidthMultiplier)

        bodyViewOffsetYConstraint.constant = hasImage ? 0 : uiConstants.bodyViewSafeAreaOffsetY

        contentView.backgroundColor = viewModel.backgroundColor
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = uiConstants.cornerRadiusForDialogView
    }

    private func layoutUIComponents() {
        bodyView.isLayoutMarginsRelativeArrangement = true
        bodyView.layoutMargins = UIEdgeInsets(top: 0, left: uiConstants.dialogViewHorizontalMargin,
                                                bottom: 0, right: uiConstants.dialogViewHorizontalMargin)

        controlsView.isLayoutMarginsRelativeArrangement = true
        controlsView.layoutMargins = UIEdgeInsets(top: 0, left: uiConstants.dialogViewHorizontalMargin,
                                                  bottom: 0, right: uiConstants.dialogViewHorizontalMargin)

        exitButton.widthAnchor.constraint(equalToConstant: uiConstants.exitButtonSize).isActive = true
        exitButton.heightAnchor.constraint(equalToConstant: uiConstants.exitButtonSize).isActive = true
        exitButtonYPositionConstraint.constant = uiConstants.exitButtonVerticalOffset
        exitButton.fontSize = uiConstants.exitButtonFontSize
    }

    private func createMessageBody(viewModel: FullViewModel) {
        bodyView.isLayoutMarginsRelativeArrangement = true
        bodyView.layoutMargins.top = uiConstants.bodyMarginTop

        if viewModel.isHTML, let htmlBody = viewModel.messageBody {
            hasImage = false
            exitButton.invertedColors = true
            bodyContainerView.isHidden = true
            setupWebView(withHtmlString: htmlBody)
        } else {
            if let headerMessage = viewModel.header {
                setupHeaderMessage(headerMessage, color: viewModel.headerColor)
            }
            setupBodyMessage(viewModel: viewModel)
        }

        presenter.loadButtons()
        updateUIComponentsVisibility(viewModel: viewModel)
    }

    private func updateUIComponentsVisibility(viewModel: FullViewModel) {
        let shouldHideBody = (viewModel.isHTML || !viewModel.hasText) &&
            !viewModel.showOptOut &&
            !viewModel.showButtons

        buttonsContainer.isHidden = !viewModel.showButtons
        optOutView.isHidden = !viewModel.showOptOut
        optOutAndButtonsSpacer.isHidden = buttonsContainer.isHidden || optOutView.isHidden
        controlsView.isHidden = buttonsContainer.isHidden && optOutView.isHidden
        bodyView.isHidden = shouldHideBody
    }

    private func setupWebView(withHtmlString htmlString: String) {
        let webView = createWebView(withHtmlString: htmlString,
                                    andFrame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false

        webViewContainer.isHidden = false
        webViewContainer.removeAllSubviews()
        webViewContainer.addSubview(webView)
        webView.constraintsFilling(parent: webViewContainer, activate: true)
    }

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

    func addButtons(_ buttons: [(ActionButton, viewModel: ActionButtonViewModel)]) {
        buttonsContainer.arrangedSubviews.forEach { buttonsContainer.removeArrangedSubview($0) }

        guard !buttons.isEmpty else {
            return
        }

        let onlyOneButton = buttons.count == 1
        let margin = onlyOneButton ? uiConstants.singleButtonWidthMargin : 0
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

    @objc private func onActionButtonClick(_ sender: ActionButton) {
        presenter.didClickAction(sender: sender)
    }

    @objc private func onExitButtonClick() {
        presenter.didClickExitButton()
    }
}
