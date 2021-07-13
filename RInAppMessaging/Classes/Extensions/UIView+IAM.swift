import UIKit

extension UIView {

    @discardableResult
    func constraintsFilling(parent: UIView, activate: Bool) -> [NSLayoutConstraint] {
        let constraints = [
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            topAnchor.constraint(equalTo: parent.topAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ]

        if activate {
            NSLayoutConstraint.activate(constraints)
        }
        return constraints
    }

    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }

    func findIAMViewSubview() -> BaseView? {
        for subview in subviews {
            if let iamView = subview as? BaseView {
                return iamView
            } else if let iamView = subview.findIAMViewSubview() {
                return iamView
            }
        }

        return nil
    }

    func isTouchInside(touchPoint point: CGPoint, from: UIView, targetView: UIView?, touchAreaSize: CGFloat) -> Bool {
        guard let targetView = targetView,
              let targetViewSuperview = targetView.superview else {
            return false
        }
        let targetViewCenter = convert(targetView.center, from: targetViewSuperview)
        let targetViewTouchArea = CGRect(origin: targetViewCenter, size: .zero)
            .insetBy(dx: -touchAreaSize / 2.0, dy: -touchAreaSize / 2.0)

        return targetViewTouchArea.contains(point)
    }
}

extension NSLayoutConstraint {
    /// Changes multiplier constraint
    /// - Parameter multiplier: The constant multiplied with the attribute
    /// on the right side of the constraint as part of getting the modified attribute.
    /// - Returns: recreated NSLayoutConstraint with modified multiplier
    @discardableResult
    func setMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {

        guard let firstItem = firstItem else {
            assertionFailure("multiplier could not be set (invalid constraint)")
            return self
        }

        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = shouldBeArchived
        newConstraint.identifier = identifier

        if isActive {
            NSLayoutConstraint.deactivate([self])
            NSLayoutConstraint.activate([newConstraint])
        }

        return newConstraint
    }
}
