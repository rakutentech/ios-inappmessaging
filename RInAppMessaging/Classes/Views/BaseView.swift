import class UIKit.UIView
import func Foundation.NSClassFromString

/// Base protocol for all of IAM's supported campaign views
internal protocol BaseView: UIView {
    var viewIdentifier: String { get }
    var onDismiss: (() -> Void)? { get set }

    /// Handle the login for displaying Modal/Fullscreen IAM views
    func show(accessibilityCompatible: Bool, onDismiss: @escaping () -> Void)

    /// Handle animation just after `show(accessibilityCompatible:onDismiss:)` call
    func animateOnShow()

    /// Dismiss the presented IAM view
    func dismiss()

    /// Return the constraints necessary for adding this view as a parent's subview
    func constraintsForParent(_ parent: UIView) -> [NSLayoutConstraint]
}

internal extension BaseView {

    var viewIdentifier: String { return "IAMView" }

    func show(accessibilityCompatible: Bool, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        displayView(accessibilityCompatible: accessibilityCompatible)
    }

    func dismiss() {
        removeFromSuperview()
        onDismiss?()
    }

    /// Find the presented view controller and add the `BaseView` on top.
    private func displayView(accessibilityCompatible: Bool) {
        self.accessibilityIdentifier = viewIdentifier

        func findPresentedIAMView(from parentView: UIView) -> UIView? {
            for subview in parentView.subviews {
                if subview.accessibilityIdentifier == viewIdentifier {
                    return subview
                } else if let iamView = findPresentedIAMView(from: subview) {
                    return iamView
                }
            }

            return nil
        }

        guard let window =  UIApplication.shared.keyWindow,
            findPresentedIAMView(from: window) == nil else {
                return
        }

        var parentView: UIView = window

        // For accessibilityCompatible option, campaign view must be inserted to
        // UIWindow's main subview. Private instance of UITransitionView
        // shouldn't be used for that - that's why it's omitted.
        if accessibilityCompatible,
            let mainSubview = window.subviews.first(
                where: { !$0.isKind(of: NSClassFromString("UITransitionView")!) }) {
            parentView = mainSubview
        }

        translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self)
        NSLayoutConstraint.activate(constraintsForParent(parentView))

        parentView.layoutIfNeeded()
        animateOnShow()
    }
}
