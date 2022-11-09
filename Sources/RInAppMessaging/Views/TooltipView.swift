import UIKit

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

    private enum UIConstants {
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
    
    let presenter: TooltipPresenterType
    private var position: TooltipBodyData.Position?
    private var imageBgColor: UIColor?
    private(set) var autoCloseTimer: Timer?
    private let exitButton = ExitButton()

    // MARK: - Init

    init(presenter: TooltipPresenterType) {
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

        setupImageView(image: model.image, position: model.position, size: imageViewSize)
        setupExitButton()
        setupShadowOffset(position: model.position)
    }

    func startAutoDisappearIfNeeded(seconds: UInt) {
        guard autoCloseTimer == nil else {
            return
        }

        let timer = Timer(fire: Date().addingTimeInterval(TimeInterval(seconds)), interval: 0, repeats: false, block: { [weak self] _ in
            self?.presenter.didTapExitButton()
        })

        autoCloseTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        exitButton.removeFromSuperview()
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

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview else {
            return
        }

        exitButton.removeFromSuperview()
        superview.addSubview(exitButton)
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

    override func removeFromSuperview() {
        super.removeFromSuperview()
        exitButton.removeFromSuperview()
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

    @objc private func didTapImage() {
        autoCloseTimer?.invalidate()
        presenter.didTapImage()
    }

    @objc private func didTapExitButton() {
        autoCloseTimer?.invalidate()
        presenter.didTapExitButton()
    }
}
