import Foundation
import UIKit
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // SPM version
#else
import RSDKUtils
#endif

internal protocol ViewListenerType: AnyObject {
    func startListening()
    func stopListening()
    func addObserver(_ observer: ViewListenerObserver)
    func iterateOverDisplayedViews(_ handler: @escaping (_ view: UIView, _ identifier: String, _ stop: inout Bool) -> Void)
}

internal protocol ViewListenerObserver: AnyObject {
    func viewDidChangeSuperview(_ view: UIView, identifier: String)
    func viewDidMoveToWindow(_ view: UIView, identifier: String)
    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String)
    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView)
}

/// A class responsible for tracking UIView changes in the hierarchy.
/// All changes are reported to registered ViewListenerObserver objects.
/// This class is based on swizzling and MUST be used as a singleton to aviod unexpected behaviour.
internal final class ViewListener: ViewListenerType {

    // A static singleton-like value is necessary for UIView methods to access this class
    static private(set) var currentInstance = ViewListener()

    @AtomicGetSet private(set) var isListening = false
    fileprivate var observers = [WeakWrapper<ViewListenerObserver>]()
    private let windowGetter: () -> UIWindow?

    private init(windowGetter: @escaping () -> UIWindow? = UIApplication.shared.getKeyWindow) {
        self.windowGetter = windowGetter
    }

    static func reinitialize(windowGetter: @escaping () -> UIWindow?) {
        currentInstance.stopListening()
        currentInstance = ViewListener(windowGetter: windowGetter)
    }

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

        iterateOverDisplayedViews { existingView, identifier, _ in
            guard !identifier.isEmpty else {
                return
            }

            existingView.didMoveToWindowNotifyObservers()
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

    func iterateOverDisplayedViews(_ handler: @escaping (UIView, String, inout Bool) -> Void) {
        guard isListening else {
            return
        }
        DispatchQueue.main.async {
            guard let allWindowSubviews = self.windowGetter()?.getAllSubviewsExceptTooltipView() else {
                return
            }
            var stop = false
            for existingView in allWindowSubviews {
                guard !stop else {
                    return
                }
                guard let identifier = existingView.accessibilityIdentifier, !identifier.isEmpty else {
                    continue
                }
                handler(existingView, identifier, &stop)
            }
        }
    }

    private func performSwizzling() -> Bool {
        [swizzle(#selector(UIView.didMoveToSuperview), with: #selector(UIView.swizzled_didMoveToSuperview)),
         swizzle(#selector(UIView.removeFromSuperview), with: #selector(UIView.swizzled_removeFromSuperview)),
         swizzle(#selector(setter: UIView.accessibilityIdentifier),
                 with: #selector(NSObject.swizzled_setAccessibilityIdentifier),
                 of: NSObject.self),
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
        let oldIdentifier = (self as? UIView)?.accessibilityIdentifier
        self.swizzled_setAccessibilityIdentifier(identifier)

        guard let self = self as? UIView, oldIdentifier != identifier else {
            return
        }
        ViewListener.currentInstance.observers.forEach {
            $0.value?.viewDidUpdateIdentifier(from: oldIdentifier, to: identifier, view: self)
        }
    }
}

private extension UIView {

    var identifier: String {
        accessibilityIdentifier ?? ""
    }

    // TOOLTIP: support isHidden

    @objc func swizzled_didMoveToSuperview() {
        self.swizzled_didMoveToSuperview()

        guard !identifier.isEmpty else {
            return
        }
        ViewListener.currentInstance.observers.forEach {
            $0.value?.viewDidChangeSuperview(self, identifier: identifier)
        }
    }

    @objc func swizzled_removeFromSuperview() {
        self.swizzled_removeFromSuperview()

        guard !identifier.isEmpty else {
            return
        }
        ViewListener.currentInstance.observers.forEach {
            $0.value?.viewDidGetRemovedFromSuperview(self, identifier: identifier)
        }
    }

    @objc func swizzled_didMoveToWindow() {
        self.swizzled_didMoveToWindow()

        guard !identifier.isEmpty else {
            return
        }
        didMoveToWindowNotifyObservers()
    }

    func didMoveToWindowNotifyObservers() {
        if window == nil {
            ViewListener.currentInstance.observers.forEach {
                $0.value?.viewDidGetRemovedFromSuperview(self, identifier: identifier)
            }
        } else {
            ViewListener.currentInstance.observers.forEach {
                $0.value?.viewDidMoveToWindow(self, identifier: identifier)
            }
        }
    }

    class func getAllSubviewsExceptTooltipView(from parentView: UIView) -> [UIView] {
        return parentView.subviews.flatMap { subView -> [UIView] in
            guard !(subView is TooltipView) else {
                return []
            }
            var result = getAllSubviewsExceptTooltipView(from: subView)
            result.append(subView)
            return result
        }
    }

    func getAllSubviewsExceptTooltipView() -> [UIView] {
        UIView.getAllSubviewsExceptTooltipView(from: self)
    }
}
