import class UIKit.UIView
import func Foundation.NSClassFromString

/// Base protocol for all of IAM's supported campaign views
internal protocol BaseView: UIView, AlertPresentable {

    static var viewIdentifier: String { get }
    var onDismiss: ((_ cancelled: Bool) -> Void)? { get set }
    var basePresenter: BaseViewPresenterType { get }

    func show(accessibilityCompatible: Bool,
              parentView: UIView,
              onDismiss: @escaping (_ cancelled: Bool) -> Void)
    func animateOnShow(completion: @escaping () -> Void)
    func dismiss()
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint]
}

internal extension BaseView {

    func show(accessibilityCompatible: Bool,
              parentView: UIView,
              onDismiss: @escaping ((_ cancelled: Bool) -> Void)) {

        self.onDismiss = onDismiss
        displayView(accessibilityCompatible: accessibilityCompatible, parentView: parentView)
    }

    func dismiss() {
        removeFromSuperview()
        onDismiss?(false)
    }

    private func displayView(accessibilityCompatible: Bool, parentView: UIView) {
        accessibilityIdentifier = accessibilityIdentifier ?? Self.viewIdentifier

        translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self)
        NSLayoutConstraint.activate(constraintsForParent(parentView))

        parentView.setNeedsLayout()
        parentView.isUserInteractionEnabled = false
        animateOnShow(completion: {
            parentView.isUserInteractionEnabled = true
        })
    }
}
