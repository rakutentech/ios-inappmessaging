import UIKit

extension UIView {

    func findIAMView() -> BaseView? {
        for subview in subviews {
            if let iamView = subview as? BaseView {
                return iamView
            } else if let nestedIAMView = subview.findIAMView() {
                return nestedIAMView
            }
        }

        return nil
    }

    func findTooltipView() -> TooltipView? {
        for subview in subviews {
            if let tooltipView = subview as? TooltipView {
                return tooltipView
            } else if let nestedTooltipView = subview.findTooltipView() {
                return nestedTooltipView
            }
        }

        return nil
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
