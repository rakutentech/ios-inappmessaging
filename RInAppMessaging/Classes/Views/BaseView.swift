import class UIKit.UIView

/// Base protocol for all of IAM's supported campaign views
internal protocol BaseView: UIView {
    var viewIdentifier: String { get }
    var onDismiss: (() -> Void)? { get set }
    var isUsingAutoLayout: Bool { get }

    /// Handle the login for displaying Modal/Fullscreen IAM views
    func show(accessibilityCompatible: Bool, onDismiss: @escaping () -> Void)

    /// Handle animation just after `show(accessibilityCompatible:onDismiss:)` call
    func animateOnShow()

    /// Dismiss the presented IAM view
    func dismiss()
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

        let parentView = accessibilityCompatible ? (window.subviews.first ?? window) : window
        if isUsingAutoLayout {
            translatesAutoresizingMaskIntoConstraints = false
            parentView.addSubview(self)
            activateConstraintsFilling(parent: parentView)
        } else {
            parentView.addSubview(self)
        }

        animateOnShow()
    }
}
