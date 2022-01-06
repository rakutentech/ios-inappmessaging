import UIKit
import func Foundation.NSClassFromString

/// Base protocol for all of IAM's supported campaign views
internal protocol BaseView: UIView, AlertPresentable {

    static var viewIdentifier: String { get }
    var onDismiss: ((_ cancelled: Bool) -> Void)? { get set }
    var basePresenter: BaseViewPresenterType { get }

    func show(parentView: UIView,
              onDismiss: @escaping (_ cancelled: Bool) -> Void)
    func animateOnShow(completion: @escaping () -> Void)
    func dismiss()
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint]
}

internal extension BaseView {

    func show(parentView: UIView,
              onDismiss: @escaping ((_ cancelled: Bool) -> Void)) {

        self.onDismiss = onDismiss
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

    func dismiss() {
        removeFromSuperview()
        onDismiss?(false)
    }
}
