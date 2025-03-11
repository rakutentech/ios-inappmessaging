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
        var bodyMessageFontSize: CGFloat = 14 // Font size for the body message.
        var headerMessageFontSize: CGFloat = 22 // Font size for the header message.
        var bodyMarginBottom: CGFloat = 18 // Distance from header (body) to top edge or image
        var buttonHeight: CGFloat = 40 // Define the height to use for the button.
        var buttonsSpacing: CGFloat = 8 // Size of the gap between the buttons when there are two buttons.
        var singleButtonWidthMargin: CGFloat = 0 // Width offset when only one button is given.
        var exitButtonSize: CGFloat = 44 // Size of the exit button.
        var dialogViewHorizontalMargin: CGFloat = 20 // The spacing between dialog view and the children elements.
        var dialogViewWidthOffset: CGFloat = 0 // Spacing on the left and right side of subviews.
        var dialogViewWidthMultiplier: CGFloat = 1 // Spacing on the left and right side of subviews.
        var bodyViewSafeAreaOffsetY: CGFloat = 0 // Offset for text content applied when there is no image
        var textTopMarginForNotDismissableCampaigns: CGFloat = 20 // A space added between top edge and text/body view when exit button is hidden.
    }

    internal enum Layout: String {
        case html
        case textOnly
        case imageOnly
        case textAndImage
        case carousel
    }

    @IBOutlet weak var carouselView: CarouselView!
    @IBOutlet private(set) weak var contentView: UIView! // Wraps dialog view to allow rounded corners
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var controlsView: UIStackView!
    @IBOutlet private weak var dialogView: UIStackView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
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
            exitButton.addTarget(self, action: #selector(onExitButtonClick), for: .touchUpInside)
        }
    }

// These are the view constants
    @IBOutlet var contentViewCenterX: NSLayoutConstraint!
    @IBOutlet var contentViewCenterY: NSLayoutConstraint!
    @IBOutlet private var contentWidthOffsetConstraint: NSLayoutConstraint!
    @IBOutlet private var bodyViewOffsetYConstraint: NSLayoutConstraint!
    @IBOutlet weak var optOutButtonTopSpacer: UIView!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    private weak var exitButtonHeightConstraint: NSLayoutConstraint!
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    private let presenter: FullViewPresenterType
    var fullViewModel: FullViewModel?

    var uiConstants = UIConstants()
    var mode: Mode {
        .none
    }
    var isOptOutChecked: Bool {
        !optOutView.isHidden && optOutView.isChecked
    }
    var onDismiss: ((_ cancelled: Bool) -> Void)?
    var basePresenter: BaseViewPresenterType {
        presenter
    }

    private var layout: Layout?
    private(set) var hasImage = false {
        didSet {
            imageView.isHidden = !hasImage
        }
    }
    private var isClickableImage = false
    var backgroundViewColor: UIColor? = .clear
    private var clickableImageUrl: String?
    private var modifyModalData: (isValidSize: Bool, isValidPosition: Bool, updatedModel: ResizeableModal?)?
    private var isValidModifyModal: Bool = false

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
        
        // Clickable Image Feature only for RMC
        if RInAppMessaging.isRMCEnvironment,
           isClickableImage {
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickCampaignImage)))
        }

        bodyViewOffsetYConstraint.constant = hasImage ? 0 : uiConstants.bodyViewSafeAreaOffsetY

        if isValidModifyModal,
            let model = fullViewModel,
           !RInAppMessaging.isRMCEnvironment {
            layoutModifyModal(fullViewModel: model)
        }

        DispatchQueue.main.async {
            // Fixes a problem with content size width being set 0.5pt too much
            // (landscape iPad), resulting in horizontal scroll bouncing.
            self.contentScrollView.contentSize.width = self.contentScrollView.bounds.width
        }
    }

    func layoutModifyModal(fullViewModel: FullViewModel) {
        if case .modal(let maxWindowHeightPercentage) = mode {
            guard let model = modifyModalData?.updatedModel,
                  let size = model.modalSize,
                  let width = size.width, let height = size.height else { return }
            
            let heightRatio = CGFloat(height)
            let widthRatio = CGFloat(width)
            
            invalidateActiveConstraints()

            contentView.translatesAutoresizingMaskIntoConstraints = false
            layoutMargins = .zero
            backgroundColor = .clear
            contentView.backgroundColor = fullViewModel.backgroundColor
            contentView.clipsToBounds = true
            contentView.layer.cornerRadius = uiConstants.cornerRadiusForDialogView
            contentView.layer.masksToBounds = false

            let isPortrait = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.interfaceOrientation.isPortrait ?? true

            // Set size for resizeable modal campaign
            contentWidthOffsetConstraint.constant = -uiConstants.dialogViewWidthOffset
            contentWidthOffsetConstraint.setMultiplier(uiConstants.dialogViewWidthMultiplier * widthRatio)
            contentViewHeightConstraint = createHeightConstraint(for: isPortrait,
                                                                 heightPercentage: maxWindowHeightPercentage,
                                                                 heightRatio: heightRatio)

            //Set position for resizeable modal campaign
            setResizableModalPosition(isValidPosition: modifyModalData?.isValidPosition, isPortrait: isPortrait, model: model)
            setModalDropShadow()
            layoutUIComponents(viewModel: fullViewModel)
        }
    }

    func setup(viewModel: FullViewModel) {
        removeAllSubviews()

        fullViewModel = viewModel
        guard mode != .none else {
            return
        }

        setupMainView()

        updateImageView(model: viewModel)

        if viewModel.isHTML {
            layout = .html
        } else if hasImage {
            layout = viewModel.hasText ? .textAndImage : .imageOnly
        } else if viewModel.hasText {
            layout = .textOnly
        } else if (viewModel.carouselData != nil) && !viewModel.hasText && RInAppMessaging.isRMCEnvironment {
            layout = .carousel
        }
        
        clickableImageUrl = viewModel.customJson?.clickableImage?.url
        isClickableImage = clickableImageUrl != nil
        modifyModalData = presenter.validateAndAdjustModifyModal(modal: viewModel.customJson?.resizableModal)
        if let modifyModalData {
            self.isValidModifyModal = modifyModalData.isValidSize && layout != .carousel && !presenter.campaign.isPushPrimer
        }

        setupAccessibility()
        updateUIConstants()
        if !isValidModifyModal {
            layoutContentView(viewModel: viewModel)
            layoutUIComponents(viewModel: viewModel)
        }
        createMessageBody(viewModel: viewModel)
        if RInAppMessaging.isRMCEnvironment,
           case .modal = mode,
           let opacity = viewModel.customJson?.background?.opacity,
           (0...1).contains(opacity) {
            backgroundViewColor = .black.withAlphaComponent(opacity)
        } else {
            backgroundViewColor = uiConstants.backgroundColor ?? viewModel.backgroundColor
        }

        backgroundView.backgroundColor = backgroundViewColor
        optOutView.useBrightColors = !viewModel.backgroundColor.isBright

        exitButton.invertedColors = viewModel.backgroundColor.isBright
        exitButton.isHidden = !viewModel.isDismissable
        if exitButton.isHidden {
            if layout == .imageOnly || layout == .carousel {
                exitButtonHeightConstraint.constant = 0
            } else {
                exitButtonHeightConstraint.constant = uiConstants.textTopMarginForNotDismissableCampaigns
            }
        }
        configureCarouselView(viewModel: viewModel)
        presenter.logImpression(type: .impression)
    }

    func updateUIConstants() {
        // to be optionally implemented by subclasses
    }

    func animateOnShow(completion: @escaping () -> Void) { completion() }

    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint] {
        constraintsFilling(parent: parent, activate: false)
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
        headerLabel.accessibilityIdentifier = "headerMessage"
        imageView.accessibilityIdentifier = "imageView"
        imageView.isAccessibilityElement = true
        optOutView.accessibilityIdentifier = "optOutView"

        if let layout = layout {
            accessibilityIdentifier = type(of: self).viewIdentifier + " data-qa=\"\(layout)\""
        }
    }

    private func updateImageView(model: FullViewModel) {
        if let image = model.image {
            hasImage = true
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
        } else {
            hasImage = false
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

        contentWidthOffsetConstraint.constant = -uiConstants.dialogViewWidthOffset
        contentWidthOffsetConstraint.setMultiplier(uiConstants.dialogViewWidthMultiplier)

        bodyViewOffsetYConstraint.constant = hasImage ? 0 : uiConstants.bodyViewSafeAreaOffsetY

        contentView.backgroundColor = viewModel.backgroundColor
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = uiConstants.cornerRadiusForDialogView
        contentViewHeightConstraint.isActive = false

        switch mode {
        case .fullScreen:
            contentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
            contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
        case .modal(let maxWindowHeightPercentage):
            contentViewHeightConstraint = contentView.heightAnchor.constraint(
                lessThanOrEqualTo: backgroundView.heightAnchor,
                multiplier: maxWindowHeightPercentage
            )
            contentViewHeightConstraint.isActive = true
            setModalDropShadow()
            
        default:
            assertionFailure("Unsupported mode")
        }
    }

    private func layoutUIComponents(viewModel: FullViewModel) {
        bodyView.isLayoutMarginsRelativeArrangement = true
        bodyView.layoutMargins = UIEdgeInsets(top: 0, left: uiConstants.dialogViewHorizontalMargin,
                                                bottom: 0, right: uiConstants.dialogViewHorizontalMargin)

        controlsView.isLayoutMarginsRelativeArrangement = true
        controlsView.layoutMargins = UIEdgeInsets(top: 0, left: uiConstants.dialogViewHorizontalMargin,
                                                  bottom: 0, right: uiConstants.dialogViewHorizontalMargin)

        exitButton.widthAnchor.constraint(equalToConstant: uiConstants.exitButtonSize).isActive = true
        exitButtonHeightConstraint = exitButton.heightAnchor.constraint(equalToConstant: uiConstants.exitButtonSize)
        exitButtonHeightConstraint.isActive = true

        if !viewModel.isDismissable && layout == .imageOnly {
            imageView.layer.cornerRadius = uiConstants.cornerRadiusForDialogView
            imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            imageView.layer.masksToBounds = true
        }
    }

    private func createMessageBody(viewModel: FullViewModel) {
        bodyView.isLayoutMarginsRelativeArrangement = true
        bodyView.layoutMargins.bottom = uiConstants.bodyMarginBottom

        if viewModel.isHTML, let htmlBody = viewModel.messageBody {
            hasImage = false
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
        if layout == .carousel {
            imageView.isHidden = true
        }
        carouselView.isHidden = layout != .carousel
        carouselView.setPageControlVisibility(isHdden: layout != .carousel)
        buttonsContainer.isHidden = !viewModel.showButtons
        optOutView.isHidden = !viewModel.showOptOut
        optOutButtonTopSpacer.isHidden = layout == .carousel && (buttonsContainer.isHidden || optOutView.isHidden)
        optOutAndButtonsSpacer.isHidden = buttonsContainer.isHidden || optOutView.isHidden
        controlsView.isHidden = buttonsContainer.isHidden && optOutView.isHidden
        bodyView.isHidden = viewModel.isHTML || !viewModel.hasText
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
        guard let bodyMessage = viewModel.messageBody else {
            bodyLabel.isHidden = true
            return
        }

        bodyLabel.isHidden = false
        bodyLabel.text = bodyMessage
        bodyLabel.textColor = viewModel.messageBodyColor
        bodyLabel.setLineSpacing(lineSpacing: 3.0)
        bodyLabel.font = .iamText(ofSize: uiConstants.bodyMessageFontSize)
        bodyLabel.textAlignment = .center
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.numberOfLines = 0
    }

    private func setupHeaderMessage(_ headerMessage: String, color: UIColor) {
        headerLabel.text = headerMessage
        headerLabel.textColor = color
        headerLabel.setLineSpacing(lineSpacing: 3.0)
        headerLabel.textAlignment = .center
        headerLabel.lineBreakMode = .byWordWrapping
        headerLabel.numberOfLines = 0
        headerLabel.font = .iamTitle(ofSize: uiConstants.headerMessageFontSize)
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

    func configureCarouselView(viewModel: FullViewModel) {
        guard layout == .carousel, let carouselData = viewModel.carouselData else { return }
        carouselView.configure(carouselData: carouselData,
                               presenter: presenter,
                               campaignMode: mode,
                               backgroundColor: viewModel.backgroundColor)
    }

    @objc private func onActionButtonClick(_ sender: ActionButton) {
        presenter.didClickAction(sender: sender)
    }

    @objc private func onExitButtonClick() {
        presenter.didClickExitButton()
    }

    @objc private func onClickCampaignImage() {
        presenter.didClickCampaignImage(url: clickableImageUrl)
    }
}

enum Mode: Equatable {
    case none
    case modal(maxWindowHeightPercentage: CGFloat)
    case fullScreen
}

extension FullView {
    private func setModalDropShadow() {
        contentView.layer.masksToBounds = false
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = .zero
        contentView.layer.shadowRadius = 10
    }

    private func createHeightConstraint(for isPortrait: Bool, heightPercentage: CGFloat, heightRatio: CGFloat) -> NSLayoutConstraint {
        let multiplier: CGFloat
        if isPortrait {
            multiplier = heightPercentage * heightRatio
        } else {
            multiplier = heightPercentage
        }
        let constraint = contentView.heightAnchor.constraint(
            lessThanOrEqualTo: backgroundView.heightAnchor,
            multiplier: multiplier
        )
        constraint.isActive = true
        return constraint
    }

    private func verticalConstraint(for alignment: String) -> NSLayoutConstraint? {
        switch VerticalAlignment(rawValue: alignment) {
        case .top:
            return contentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        case .center:
            return contentView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        case .bottom:
            return contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        default:
            return nil
        }
    }

    private func horizontalConstraint(for alignment: String) -> NSLayoutConstraint? {
        switch HorizontalAlignment(rawValue: alignment) {
        case .left:
            return contentView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Constants.ResizeableModal.minSpacing)
        case .center:
            return contentView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor)
        case .right:
            return contentView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -Constants.ResizeableModal.minSpacing)
        default:
            return nil
        }
    }

    private func setResizableModalPosition(isValidPosition: Bool?, isPortrait: Bool, model: ResizeableModal) {
        if let isValidPosition = modifyModalData?.isValidPosition, isValidPosition,
           let verticalAlign = model.modalPosition?.verticalAlign,
           let horizontalAlign = model.modalPosition?.horizontalAlign, isPortrait {
            portraitConstraints = [
                verticalConstraint(for: verticalAlign),
                horizontalConstraint(for: horizontalAlign)
            ].compactMap { $0 }
        } else {
            // If position is not valid then keep the campaign at center for potrait, for landscape keep it always at center
            let defaultConstraints = [
                contentView.centerXAnchor.constraint(equalTo: backgroundView.safeAreaLayoutGuide.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: backgroundView.safeAreaLayoutGuide.centerYAnchor)
            ]

            if isPortrait {
                portraitConstraints = defaultConstraints
            } else {
                landscapeConstraints = defaultConstraints
            }
        }
        NSLayoutConstraint.activate(isPortrait ? portraitConstraints : landscapeConstraints)
    }

    private func invalidateActiveConstraints() {
        NSLayoutConstraint.deactivate(portraitConstraints + landscapeConstraints)
        portraitConstraints.removeAll()
        landscapeConstraints.removeAll()

        if let contentViewCenterX, let contentViewCenterY, let contentViewHeightConstraint {
            contentViewCenterX.isActive = false
            contentViewCenterY.isActive = false
            contentViewHeightConstraint.isActive = false
        }
    }
}
