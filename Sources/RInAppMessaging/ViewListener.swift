import Foundation
import UIKit
import RSDKUtils

internal protocol ViewListenerType: AnyObject {
    func startListening()
    func stopListening()
    func addObserver(_ observer: ViewListenerObserver)
}

internal protocol ViewListenerObserver: AnyObject {
    func viewDidChangeSubview(_ view: UIView, identifier: String)
    func viewDidMoveToWindow(_ view: UIView, identifier: String)
    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String)
    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView)
}

internal final class ViewListener: ViewListenerType {

    static let instance = ViewListener()

    @AtomicGetSet private(set) var isListening = false
    fileprivate var observers = [WeakWrapper<ViewListenerObserver>]()

    private init() { }

    func startListening() {
        guard !isListening else {
            return
        }

        isListening = true
        guard performSwizzling() else {
            isListening = false
            assertionFailure()
            _ = performSwizzling() // try to restore original implementations
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.getKeyWindow()?.getAllSubviews().forEach { existingView in
                guard let identifier = existingView.accessibilityIdentifier, !identifier.isEmpty else {
                    return
                }
                self.observers.forEach {
                    $0.value?.viewDidMoveToWindow(existingView, identifier: identifier)
                }
            }
        }
    }

    func stopListening() {
        guard isListening else {
            return
        }

        isListening = false
        guard performSwizzling() else {
            isListening = true
            assertionFailure()
            return
        }
    }

    func addObserver(_ observer: ViewListenerObserver) {
        observers.append(WeakWrapper(value: observer))
    }

    private func performSwizzling() -> Bool {
        [swizzle(#selector(UIView.didMoveToSuperview), with: #selector(UIView.swizzled_didMoveToSuperview)),
         swizzle(#selector(UIView.removeFromSuperview), with: #selector(UIView.swizzled_removeFromSuperview)),
         swizzle(#selector(setter: UIView.accessibilityIdentifier),
                 with: #selector(NSObject.swizzled_setAccessibilityIdentifier),
                 of: NSObject.self),
         swizzle(#selector(setter: UILabel.text),
                 with: #selector(UILabel.swizzled_setText),
                 of: UILabel.self),
         swizzle(#selector(setter: UILabel.attributedText),
                 with: #selector(UILabel.swizzled_setAttributedText),
                 of: UILabel.self),
         swizzle(#selector(setter: UITextView.attributedText),
                 with: #selector(UITextView.swizzled_setAttributedText),
                 of: UITextView.self),
         swizzle(#selector(UIView.didMoveToWindow), with: #selector(UIView.swizzled_didMoveToWindow))].allSatisfy { $0 == true }
    }

    private func swizzle(_ sel1: Selector, with sel2: Selector, of class: AnyClass = UIView.self) -> Bool {
        guard let originalMethod = class_getInstanceMethod(`class`, sel1),
              let swizzledMethod = class_getInstanceMethod(`class`, sel2) else {
                  assertionFailure()
                  return false
              }

        method_exchangeImplementations(originalMethod, swizzledMethod)

        return true
    }
}

private extension NSObject {
    @objc func swizzled_setAccessibilityIdentifier(_ identifier: String?) {
        let oldIdentifier = (self as? UIAccessibilityIdentification)?.accessibilityIdentifier
        self.swizzled_setAccessibilityIdentifier(identifier)

        guard let self = self as? UIView else {
            return
        }
        let newIdentifier = identifier ?? (self as? UILabel)?.text ?? (self as? UITextView)?.text
        ViewListener.instance.observers.forEach {
            $0.value?.viewDidUpdateIdentifier(from: oldIdentifier ?? (self as? UILabel)?.text ?? (self as? UITextView)?.text, to: newIdentifier, view: self)
        }
    }
}

private extension UILabel {
    @objc func swizzled_setText(_ newText: String?) {
        let oldText = text
        self.swizzled_setText(newText)

        let newIdentifier = accessibilityIdentifier ?? newText
        ViewListener.instance.observers.forEach {
            $0.value?.viewDidUpdateIdentifier(from: accessibilityIdentifier ?? oldText, to: newIdentifier, view: self)
        }
    }

    @objc func swizzled_setAttributedText(_ newText: NSAttributedString?) {
        let oldText = attributedText
        self.swizzled_setAttributedText(newText)

        let newIdentifier = accessibilityIdentifier ?? newText?.string
        ViewListener.instance.observers.forEach {
            $0.value?.viewDidUpdateIdentifier(from: accessibilityIdentifier ?? oldText?.string, to: newIdentifier, view: self)
        }
    }
}

private extension UITextView { // to be removed
    @objc func swizzled_setAttributedText(_ newText: NSAttributedString?) {
        let oldText = newText
        self.swizzled_setAttributedText(newText)

        let newIdentifier = accessibilityIdentifier ?? newText?.string
        ViewListener.instance.observers.forEach {
            $0.value?.viewDidUpdateIdentifier(from: accessibilityIdentifier ?? oldText?.string, to: newIdentifier, view: self)
        }
    }
}

private extension UIView {

    var identifier: String {
        accessibilityIdentifier ?? (self as? UILabel)?.text ?? (self as? UITextView)?.text ?? ""
    }

    // TOOLTIP: support isHidden

    @objc func swizzled_didMoveToSuperview() {
        self.swizzled_didMoveToSuperview()

        guard !identifier.isEmpty else {
            return
        }
        ViewListener.instance.observers.forEach {
            $0.value?.viewDidChangeSubview(self, identifier: identifier)
        }
    }

    @objc func swizzled_removeFromSuperview() {
        self.swizzled_removeFromSuperview()

        guard !identifier.isEmpty else {
            return
        }
        ViewListener.instance.observers.forEach {
            $0.value?.viewDidGetRemovedFromSuperview(self, identifier: identifier)
        }
    }

    @objc func swizzled_didMoveToWindow() {
        self.swizzled_didMoveToWindow()

        guard !identifier.isEmpty else {
            return
        }
        if window == nil {
            ViewListener.instance.observers.forEach {
                $0.value?.viewDidGetRemovedFromSuperview(self, identifier: identifier)
            }
        } else {
            ViewListener.instance.observers.forEach {
                $0.value?.viewDidMoveToWindow(self, identifier: identifier)
            }
        }
    }

    class func getAllSubviews(from parentView: UIView) -> [UIView] {
        return parentView.subviews.flatMap { subView -> [UIView] in
            var result = getAllSubviews(from: subView)
            result.append(subView)
            return result
        }
    }

    func getAllSubviews() -> [UIView] {
        UIView.getAllSubviews(from: self)
    }
}
