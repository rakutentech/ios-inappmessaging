import UIKit
import SwiftUI

#if SWIFT_PACKAGE
import RSDKUtilsMain
#else
import RSDKUtils
#endif

enum TooltipLayoutConstants {
    static let minDistanceFromEdge: CGFloat = 20.0
    static let targetViewSpacing: CGFloat = 0.0
}

internal struct TooltipViewModel {
    let position: TooltipBodyData.Position
    let image: UIImage
    let backgroundColor: UIColor
}

/// TooltipView class draws the shape of tooltip and displays its image.
/// The view is supposed to be presented on top of view hierarchy or in the first parent scroll view.
/// The exit button is addeded as a sibling view - not a subview (to aviod drawing and interaction issues).
/// Tooltip can be presented in 8 different positions around the target view.
/// TooltipView's frame and visiblity must be updated along with target view's updates.
/// Tooltips can be dismissed by tapping the exit button or the image, or it can disappear automatically if timeout is specified.
internal class TooltipView: UIView {

    fileprivate enum UIConstants {
        static let tipSize = CGSize(width: 8.0, height: 8.0)
        static let cornerRadius: CGFloat = 6.0
        static let imagePadding: CGFloat = 4.0
        static let exitButtonSize: CGFloat = 20
        static let exitButtonTopMargin: CGFloat = -4.0
        static let exitButtonRightMargin: CGFloat = 4.0
        static let exitButtonTouchAreaSize: CGFloat = 44
        static let shadowRadius: CGFloat = 5.0
        static let shadowOpacity: Float = 0.75

        // The base of the tip (width) in top-left/right and bottom-left/right position
        // gets inside the rectangle that holds the image that way, the base's vertexes are on the rectangle's edges.
        // a^2 + b^2 = c^2 | c = UIConstants.tipSize.width | a = b
        static let cornerTipOffset: CGFloat = ceil(sqrt(tipSize.width * tipSize.width / 2.0)) // a = sqrt(c^2/2)

        // On corners, the tip's size must be slightly bigger to look normal.
        // Tip's base is drawn entirely inside the image's rectangle.
        static let cornerTipSize = CGSize(width: tipSize.width,
                                          height: ceil(tipSize.height / sqrt(2)))
    }
    
    var presenter: TooltipPresenterType?
    var onDeinit: (() -> Void)?
    private var position: TooltipBodyData.Position? {
        didSet {
            if #available(iOS 15.0, *), let position = position {
                (coordinator as? TooltipViewSwiftUI.Coordinator)?.setPosition(position)
            }
        }
    }
    private var imageBgColor: UIColor?
    private let exitButton = ExitButton()

    // Erased type to keep TooltipView compatible with older iOS versions
    fileprivate var coordinator: Any?

    // MARK: - Init

    init(presenter: TooltipPresenterType?) {
        self.presenter = presenter
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = false
        autoresizingMask = []
        accessibilityIdentifier = "IAMView-Tooltip"

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = UIConstants.shadowRadius
        layer.shadowOpacity = UIConstants.shadowOpacity
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        onDeinit?()
        exitButton.removeFromSuperview()
    }

    func setup(model: TooltipViewModel) {
        position = model.position
        imageBgColor = model.backgroundColor

        let imageViewSize = model.image.size.applying(.init(scaleX: 1.0 / UIScreen.main.scale, y: 1.0 / UIScreen.main.scale)) // convert pixels to points
        var frame = CGRect(origin: .zero, size: CGSize(width: imageViewSize.width + UIConstants.imagePadding * 2,
                                                       height: imageViewSize.height + UIConstants.imagePadding * 2))
        switch model.position {
        case .bottomRight, .bottomLeft, .topLeft, .topRight:
            frame.size.width += UIConstants.cornerTipSize.height
            frame.size.height += UIConstants.cornerTipSize.height
        case .bottomCenter, .topCenter:
            frame.size.height += UIConstants.tipSize.height
        case .left, .right:
            frame.size.width += UIConstants.tipSize.height
        }
        self.frame = frame

        widthAnchor.constraint(equalToConstant: frame.size.width).isActive = true
        heightAnchor.constraint(equalToConstant: frame.size.height).isActive = true

        setupImageView(image: model.image, position: model.position, size: imageViewSize)
        setupExitButton()
        setupShadowOffset(position: model.position)
        didAppearAsSwiftUI()
    }

    // MARK: - UIView overrides

    override func draw(_ rect: CGRect) {
        guard let imageBgColor = imageBgColor, let position = position else {
            return
        }

        imageBgColor.set()
        let path: UIBezierPath

        switch position {
        case .topCenter:
            let imageRectSize = CGSize(width: bounds.size.width,
                                       height: bounds.size.height - UIConstants.tipSize.height)
            path = UIBezierPath(roundedRect: CGRect(origin: .zero,
                                                    size: CGSize(width: bounds.width, height: imageRectSize.height)),
                                cornerRadius: UIConstants.cornerRadius)
            path.move(to: CGPoint(x: bounds.midX - UIConstants.tipSize.width / 2.0, y: imageRectSize.height))
            path.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
            path.addLine(to: CGPoint(x: bounds.midX + UIConstants.tipSize.width / 2.0, y: imageRectSize.height))

        case .topLeft:
            let imageRectSize = CGSize(width: bounds.size.width - UIConstants.cornerTipSize.height,
                                       height: bounds.size.height - UIConstants.cornerTipSize.height)
            path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageRectSize),
                                cornerRadius: UIConstants.cornerRadius)
            path.fill()
            path.stroke() // this fill() and stroke() fix drawing issue where tip overlaps the image rect (corner positions)
            path.move(to: CGPoint(x: imageRectSize.width - UIConstants.cornerTipOffset, y: imageRectSize.height))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
            path.addLine(to: CGPoint(x: imageRectSize.width, y: imageRectSize.height - UIConstants.cornerTipOffset))

        case .topRight:
            let imageRectSize = CGSize(width: bounds.size.width - UIConstants.cornerTipSize.height,
                                       height: bounds.size.height - UIConstants.cornerTipSize.height)
            path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: UIConstants.cornerTipSize.height, y: 0),
                                                    size: imageRectSize),
                                cornerRadius: UIConstants.cornerRadius)
            path.fill()
            path.stroke()
            path.move(to: CGPoint(x: UIConstants.cornerTipSize.height + UIConstants.cornerTipOffset, y: imageRectSize.height))
            path.addLine(to: CGPoint(x: 0, y: bounds.maxY))
            path.addLine(to: CGPoint(x: UIConstants.cornerTipSize.height, y: imageRectSize.height - UIConstants.cornerTipOffset))

        case .bottomLeft:
            let imageRectSize = CGSize(width: bounds.size.width - UIConstants.cornerTipSize.height,
                                       height: bounds.size.height - UIConstants.cornerTipSize.height)
            path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: UIConstants.cornerTipSize.height),
                                                    size: imageRectSize),
                                cornerRadius: UIConstants.cornerRadius)
            path.fill()
            path.stroke()
            path.move(to: CGPoint(x: imageRectSize.width - UIConstants.cornerTipOffset, y: UIConstants.cornerTipSize.height))
            path.addLine(to: CGPoint(x: bounds.maxX, y: 0))
            path.addLine(to: CGPoint(x: imageRectSize.width, y: UIConstants.cornerTipSize.height + UIConstants.cornerTipOffset))

        case .bottomRight:
            let imageRectSize = CGSize(width: bounds.size.width - UIConstants.cornerTipSize.height,
                                       height: bounds.size.height - UIConstants.cornerTipSize.height)
            path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: UIConstants.cornerTipSize.height, y: UIConstants.cornerTipSize.height),
                                                    size: imageRectSize),
                                cornerRadius: UIConstants.cornerRadius)
            path.fill()
            path.stroke()
            path.move(to: CGPoint(x: UIConstants.cornerTipSize.height + UIConstants.cornerTipOffset, y: UIConstants.cornerTipSize.height))
            path.addLine(to: .zero)
            path.addLine(to: CGPoint(x: UIConstants.cornerTipSize.height, y: UIConstants.cornerTipSize.height + UIConstants.cornerTipOffset))

        case .bottomCenter:
            let imageRectSize = CGSize(width: bounds.size.width,
                                       height: bounds.size.height - UIConstants.tipSize.height)
            path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: UIConstants.tipSize.height),
                                                    size: imageRectSize),
                                cornerRadius: UIConstants.cornerRadius)
            path.move(to: CGPoint(x: bounds.midX - UIConstants.tipSize.width / 2.0, y: UIConstants.tipSize.height))
            path.addLine(to: CGPoint(x: bounds.midX, y: 0))
            path.addLine(to: CGPoint(x: bounds.midX + UIConstants.tipSize.width / 2.0, y: UIConstants.tipSize.height))

        case .left:
            let imageRectSize = CGSize(width: bounds.size.width - UIConstants.tipSize.height,
                                       height: bounds.size.height)
            path = UIBezierPath(roundedRect: CGRect(origin: .zero,
                                                    size: imageRectSize),
                                cornerRadius: UIConstants.cornerRadius)
            path.move(to: CGPoint(x: bounds.maxX - UIConstants.tipSize.height, y: bounds.midY - UIConstants.tipSize.width / 2.0))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
            path.addLine(to: CGPoint(x: bounds.maxX - UIConstants.tipSize.height, y: bounds.midY + UIConstants.tipSize.width / 2.0))

        case .right:
            let imageRectSize = CGSize(width: bounds.size.width - UIConstants.tipSize.height,
                                       height: bounds.size.height)
            path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: UIConstants.tipSize.height, y: 0),
                                                    size: imageRectSize),
                                cornerRadius: UIConstants.cornerRadius)
            path.move(to: CGPoint(x: UIConstants.tipSize.height, y: bounds.midY - UIConstants.tipSize.width / 2.0))
            path.addLine(to: CGPoint(x: 0, y: bounds.midY))
            path.addLine(to: CGPoint(x: UIConstants.tipSize.height, y: bounds.midY + UIConstants.tipSize.width / 2.0))
        }

        path.fill()
        layer.shadowPath = path.cgPath
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        exitButton.removeFromSuperview()
        presenter?.didRemoveFromSuperview()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if exitButton.isTouchInside(touchPoint: point, from: self, touchAreaSize: UIConstants.exitButtonTouchAreaSize) {
            return exitButton
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - Private methods

    private func setupImageView(image: UIImage,
                                position: TooltipBodyData.Position,
                                size: CGSize) {
        let imageView = UIImageView()
        imageView.autoresizingMask = []
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapImage)))
        addSubview(imageView)

        imageView.frame = CGRect(origin: CGPoint(x: UIConstants.imagePadding, y: UIConstants.imagePadding),
                                 size: size)
        switch position {
        case .topRight:
            imageView.frame.origin.x += UIConstants.cornerTipSize.height
        case .right:
            imageView.frame.origin.x += UIConstants.tipSize.height
        case .bottomLeft:
            imageView.frame.origin.y += UIConstants.cornerTipSize.height
        case .bottomCenter:
            imageView.frame.origin.y += UIConstants.tipSize.height
        case .bottomRight:
            imageView.frame.origin.x += UIConstants.cornerTipSize.height
            imageView.frame.origin.y += UIConstants.cornerTipSize.height
        default: ()
        }
    }

    private func setupExitButton() {
        exitButton.invertedColors = false
        exitButton.addTarget(self, action: #selector(didTapExitButton), for: .touchUpInside)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.accessibilityIdentifier = "IAM.tooltip.exitButton"

        exitButton.backgroundColor = UIColor(white: 77.0/255.0, alpha: 1.0)
        exitButton.layer.shadowColor = UIColor.black.cgColor
        exitButton.layer.shadowRadius = UIConstants.shadowRadius
        exitButton.layer.shadowOpacity = UIConstants.shadowOpacity

        addSubview(exitButton)
        var constraints = [
            exitButton.widthAnchor.constraint(equalToConstant: UIConstants.exitButtonSize),
            exitButton.heightAnchor.constraint(equalToConstant: UIConstants.exitButtonSize)
        ]

        if [.left, .topLeft, .bottomLeft].contains(position) {
            constraints.append(exitButton.rightAnchor.constraint(equalTo: self.leftAnchor,
                                                                 constant: -UIConstants.exitButtonRightMargin))
        } else {
            constraints.append(exitButton.leftAnchor.constraint(equalTo: self.rightAnchor,
                                                                constant: UIConstants.exitButtonRightMargin))
        }
        if [.bottomRight, .bottomLeft].contains(position) {
            constraints.append(exitButton.bottomAnchor.constraint(equalTo: self.topAnchor,
                                                                  constant: -UIConstants.exitButtonTopMargin + UIConstants.tipSize.height))
        }
        else if position == .bottomCenter {
            constraints.append(exitButton.bottomAnchor.constraint(equalTo: self.bottomAnchor,
                                                                  constant: -UIConstants.exitButtonTopMargin + UIConstants.tipSize.height))
        } else {
            constraints.append(exitButton.bottomAnchor.constraint(equalTo: self.topAnchor,
                                                                  constant: -UIConstants.exitButtonTopMargin))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func setupShadowOffset(position: TooltipBodyData.Position) {
        let shadowOffset: CGSize
        switch position {
        case .topRight:
            shadowOffset = CGSize(width: -1, height: 2)
        case .right:
            shadowOffset = CGSize(width: -1, height: 2)
        case .bottomLeft:
            shadowOffset = CGSize(width: 1, height: -2)
        case .bottomCenter:
            shadowOffset = CGSize(width: 1, height: -2)
        case .bottomRight:
            shadowOffset = CGSize(width: -1, height: -2)
        case .topLeft:
            shadowOffset = CGSize(width: 1, height: 2)
        case .topCenter:
            shadowOffset = CGSize(width: 1, height: 2)
        case .left:
            shadowOffset = CGSize(width: 1, height: 2)
        }

        exitButton.layer.shadowOffset = shadowOffset
        layer.shadowOffset = shadowOffset
    }

    private func didAppearAsSwiftUI() {
        isHidden = false
        presenter?.startAutoDisappearIfNeeded()
        if #available(iOS 15.0, *) {
            let coordinator = coordinator as? TooltipViewSwiftUI.Coordinator
            coordinator?.updateSize(bounds.size)
            coordinator?.updateVisibility(true)
        }
    }

    @objc private func didTapImage() {
        presenter?.didTapImage()
    }

    @objc private func didTapExitButton() {
        presenter?.didTapExitButton()
        if #available(iOS 15.0, *) {
            (coordinator as? TooltipViewSwiftUI.Coordinator)?.updateVisibility(false)
        }
    }
}

@available(iOS 15.0, *)
internal struct TooltipViewSwiftUI: UIViewRepresentable {

    enum UIConstants {
        static let containerViewPadding = TooltipView.UIConstants.exitButtonTouchAreaSize
    }

    let identifier: String
    var iamModule: SwiftUITooltipManageable.Type = RInAppMessaging.self
    @ObservedObject private var state: TooltipViewState

    init(identifier: String, state: TooltipViewState) {
        self.identifier = identifier
        self.state = state
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tooltipView = TooltipView(presenter: nil)
        tooltipView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tooltipView)
        tooltipView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        tooltipView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

        iamModule.registerSwiftUITooltip(identifier: identifier, uiView: tooltipView)
        tooltipView.coordinator = context.coordinator
        tooltipView.isHidden = true
        return containerView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let tooltipView = uiView.subviews.first as? TooltipView else {
            return
        }
        tooltipView.setNeedsDisplay()
        tooltipView.setNeedsLayout()
    }
}

@available(iOS 15.0, *)
extension TooltipViewSwiftUI {
    struct Coordinator {
        @ObservedObject private var state: TooltipViewState

        init(state: TooltipViewState) {
            self.state = state
        }

        func updateVisibility(_ newValue: Bool) {
            state.isVisible = newValue
        }

        func setPosition(_ position: TooltipBodyData.Position) {
            state.position = position
        }

        func updateSize(_ size: CGSize) {
            state.innerSize = size
        }
    }
}

@available(iOS 15.0, *)
class TooltipViewState: ObservableObject {
    // For some reason if the first state is hidden (isVisible = false), the tooltip will never appear even if the state changes.
    // As a workaround, the first isVisible value is true with UIView's `isHidden` value set to true.
    @Published var isVisible: Bool = true
    @Published var position: TooltipBodyData.Position = .bottomCenter
    @Published var innerSize: CGSize = .zero
}

@available(iOS 15.0, *)
struct TooltipViewModifier: ViewModifier {

    let identifier: String
    var iamModule: SwiftUITooltipManageable.Type = RInAppMessaging.self
    private var tooltipContainerSize: CGSize {
        // To keep exit button tappable, its bounds (and touch area) must fit inside the container view bounds
        .init(width: state.innerSize.width + TooltipViewSwiftUI.UIConstants.containerViewPadding * 2,
              height: state.innerSize.height + TooltipViewSwiftUI.UIConstants.containerViewPadding * 2)
    }

    @StateObject private var state = TooltipViewState()

    func body(content: Self.Content) -> some View {
        content.overlay {
            GeometryReader { geometry in
                TooltipViewSwiftUI(identifier: identifier, state: state)
                    .onAppear {
                        iamModule.verifySwiftUITooltip(identifier: identifier)
                    }
                    .isHidden(!state.isVisible)
                    .position(getCenter(geometry: geometry))
                    .frame(width: tooltipContainerSize.width, height: tooltipContainerSize.height)
            }
        }
    }

    private func getCenter(geometry: GeometryProxy) -> CGPoint {
        let targetViewFrame = geometry.frame(in: .local)
        let tooltipSize = state.innerSize
        let cornerSpacing = TooltipLayoutConstants.targetViewSpacing / sqrt(2)

        switch state.position {
        case .topCenter:
            return CGPoint(x: targetViewFrame.midX,
                           y: targetViewFrame.origin.y - tooltipSize.height / 2.0 - TooltipLayoutConstants.targetViewSpacing)
        case .topLeft:
            return CGPoint(x: targetViewFrame.minX - tooltipSize.width / 2.0 - cornerSpacing,
                           y: targetViewFrame.origin.y - tooltipSize.height / 2.0 - cornerSpacing)
        case .topRight:
            return CGPoint(x: targetViewFrame.maxX + tooltipSize.width / 2.0 + cornerSpacing,
                           y: targetViewFrame.origin.y - tooltipSize.height / 2.0 - cornerSpacing)
        case .bottomLeft:
            return CGPoint(x: targetViewFrame.minX - tooltipSize.width / 2.0 - cornerSpacing,
                           y: targetViewFrame.maxY + tooltipSize.height / 2.0 + cornerSpacing)
        case .bottomRight:
            return CGPoint(x: targetViewFrame.maxX + tooltipSize.width / 2.0 + cornerSpacing,
                           y: targetViewFrame.maxY + tooltipSize.height / 2.0 + cornerSpacing)
        case .bottomCenter:
            return CGPoint(x: targetViewFrame.midX,
                           y: targetViewFrame.maxY + tooltipSize.height / 2.0 + TooltipLayoutConstants.targetViewSpacing)
        case .left:
            return CGPoint(x: targetViewFrame.minX - tooltipSize.width / 2.0 - TooltipLayoutConstants.targetViewSpacing,
                           y: targetViewFrame.midY)
        case .right:
            return CGPoint(x: targetViewFrame.maxX + tooltipSize.width / 2.0 + TooltipLayoutConstants.targetViewSpacing,
                           y: targetViewFrame.midY)
        }
    }
}

@available(iOS 15.0, *)
public extension View {
    func canHaveTooltip(identifier: String) -> some View {
        modifier(TooltipViewModifier(identifier: identifier))
    }
}
