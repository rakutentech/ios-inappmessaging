import class UIKit.UIView
import func Foundation.NSClassFromString

/// Base protocol for all of IAM's supported campaign views
internal protocol BaseView: UIView {

    static var viewIdentifier: String { get }
    var onDismiss: (() -> Void)? { get set }

    func show(accessibilityCompatible: Bool,
              parentView: UIView,
              onDismiss: @escaping () -> Void)
    func animateOnShow(completion: @escaping () -> Void)
    func dismiss()
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint]
}

internal extension BaseView {

    static var viewIdentifier: String { return "IAMView" }

    func show(accessibilityCompatible: Bool,
              parentView: UIView,
              onDismiss: @escaping () -> Void) {

        self.onDismiss = onDismiss
        displayView(accessibilityCompatible: accessibilityCompatible, parentView: parentView)
    }

    func dismiss() {
        removeFromSuperview()
        onDismiss?()
    }

    private func displayView(accessibilityCompatible: Bool, parentView: UIView) {
        accessibilityIdentifier = Self.viewIdentifier

        translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self)
        NSLayoutConstraint.activate(constraintsForParent(parentView))

        parentView.layoutIfNeeded()
        parentView.isUserInteractionEnabled = false
        animateOnShow(completion: {
            parentView.isUserInteractionEnabled = true
        })
    }
}
