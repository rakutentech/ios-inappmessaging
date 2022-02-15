import Foundation
import Quick
import Nimble
import UIKit
#if canImport(RSDKUtilsNimble)
import RSDKUtilsNimble // SPM version
#else
import RSDKUtils
#endif
@testable import RInAppMessaging

class ViewListenerSpec: QuickSpec {

    override func spec() {
        describe("ViewListener") {

            let viewListener = ViewListener.instance
            let window = UIApplication.shared.getKeyWindow()!

            afterEach {
                viewListener.stopListening()
            }

            it("will not crash when startListening is called multiple times") {
                viewListener.startListening()
                viewListener.startListening()
            }

            it("will not crash when stopListening is called multiple times") {
                viewListener.stopListening()
                viewListener.stopListening()
            }

            context("when calling iterateOverDisplayedViews") {

                it("will include all views in hierarchy") {
                    let view1 = UIView()
                    view1.accessibilityIdentifier = TooltipViewIdentifierMock
                    let view2 = UIView()
                    view2.accessibilityIdentifier = TooltipViewIdentifierMock
                    let view3 = UIView()
                    view3.accessibilityIdentifier = TooltipViewIdentifierMock
                    let subview1 = UIView()
                    let subview2 = UIView()
                    subview1.addSubview(subview2)
                    subview2.addSubview(view3)
                    [view1, view2, subview1].forEach {
                        window.addSubview($0)
                    }

                    viewListener.startListening()
                    var expectedViews = [UIView]()
                    viewListener.iterateOverDisplayedViews { view, identifier, _ in
                        if identifier == TooltipViewIdentifierMock {
                            expectedViews.append(view)
                        }
                    }
                    expect(expectedViews).toEventually(elementsEqualOrderAgnostic([view1, view2, view3]))

                    [view1, view2, subview1].forEach {
                        $0.removeFromSuperview()
                    }
                }

                it("will stop iterating when stop flag was set to true in the closure") {
                    let view1 = UIView()
                    let view2 = UIView()
                    [view1, view2].forEach {
                        window.addSubview($0)
                    }

                    viewListener.startListening()
                    var expectedViews = [UIView]()
                    viewListener.iterateOverDisplayedViews { view, _, stop in
                        expectedViews.append(view)
                        stop = true
                    }
                    expect(expectedViews).toAfterTimeout(haveCount(1))

                    [view1, view2].forEach {
                        $0.removeFromSuperview()
                    }
                }

                it("will not call closure when startListening() was not called") {
                    let view1 = UIView()
                    window.addSubview(view1)

                    var expectedViews = [UIView]()
                    viewListener.iterateOverDisplayedViews { view, _, _ in
                        expectedViews.append(view)
                    }
                    expect(expectedViews).toAfterTimeout(beEmpty())

                    view1.removeFromSuperview()
                }
            }

            describe("ViewListenerObserver") {

                var observer: ViewListenerObserverObject!
                var view: UIView!

                beforeEach {
                    observer = ViewListenerObserverObject()
                    viewListener.addObserver(observer)
                    view = UIView()
                    view.accessibilityIdentifier = TooltipViewIdentifierMock
                    window.addSubview(view)

                    viewListener.startListening()
                    // wait for iterateOverDisplayedViews to finish
                    expect(observer.wasViewDidMoveToWindowCalled).toEventually(beTrue())
                }

                afterEach {
                    observer = nil
                    view.removeFromSuperview()
                }

                it("will get notified when startListening() was called") {
                    viewListener.stopListening()
                    observer.wasViewDidMoveToWindowCalled = false

                    viewListener.startListening()
                    expect(observer.wasViewDidMoveToWindowCalled).toEventually(beTrue())
                }

                it("will get notified when view moved to window") {
                    observer.wasViewDidMoveToWindowCalled = false
                    view.didMoveToWindow()
                    expect(observer.wasViewDidMoveToWindowCalled).toEventually(beTrue())
                }

                it("will not get notified when view without identifier moved to window") {
                    observer.wasViewDidMoveToWindowCalled = false
                    view.accessibilityIdentifier = nil
                    view.didMoveToWindow()
                    expect(observer.wasViewDidMoveToWindowCalled).toAfterTimeout(beFalse())
                }

                it("will not get notified when view with empty identifier moved to window") {
                    observer.wasViewDidMoveToWindowCalled = false
                    view.accessibilityIdentifier = ""
                    view.didMoveToWindow()
                    expect(observer.wasViewDidMoveToWindowCalled).toAfterTimeout(beFalse())
                }

                it("will get notified when view moved to superview") {
                    observer.wasViewDidChangeSuperviewCalled = false
                    view.didMoveToSuperview()
                    expect(observer.wasViewDidChangeSuperviewCalled).toEventually(beTrue())
                }

                it("will not get notified when view without identifier moved to superview") {
                    observer.wasViewDidChangeSuperviewCalled = false
                    view.accessibilityIdentifier = nil
                    view.didMoveToSuperview()
                    expect(observer.wasViewDidChangeSuperviewCalled).toAfterTimeout(beFalse())
                }

                it("will not get notified when view with empty identifier moved to superview") {
                    observer.wasViewDidChangeSuperviewCalled = false
                    view.accessibilityIdentifier = ""
                    view.didMoveToSuperview()
                    expect(observer.wasViewDidChangeSuperviewCalled).toAfterTimeout(beFalse())
                }

                it("will get notified when view got removed from superview") {
                    observer.wasViewDidGetRemovedFromSuperview = false
                    view.removeFromSuperview()
                    expect(observer.wasViewDidGetRemovedFromSuperview).toEventually(beTrue())
                }

                it("will not get notified when view without identifier got removed from superview") {
                    observer.wasViewDidGetRemovedFromSuperview = false
                    view.accessibilityIdentifier = nil
                    view.removeFromSuperview()
                    expect(observer.wasViewDidGetRemovedFromSuperview).toAfterTimeout(beFalse())
                }

                it("will not get notified when view with empty identifier got removed from superview") {
                    observer.wasViewDidGetRemovedFromSuperview = false
                    view.accessibilityIdentifier = ""
                    view.removeFromSuperview()
                    expect(observer.wasViewDidGetRemovedFromSuperview).toAfterTimeout(beFalse())
                }

                context("when displayed view changes its identifier") {

                    it("will get notified for change from valueA to valueB") {
                        view.accessibilityIdentifier = "idA"
                        view.accessibilityIdentifier = "idB"
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventually(equal(("idA", "idB", view)))
                    }

                    it("will get notified for change from nil to valueA") {
                        view.accessibilityIdentifier = nil
                        view.accessibilityIdentifier = "idA"
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventually(equal((nil, "idA", view)))
                    }

                    it("will get notified for change from valueA to nil") {
                        view.accessibilityIdentifier = "idA"
                        view.accessibilityIdentifier = nil
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventually(equal(("idA", nil, view)))
                    }

                    it("will get notified for change from valueA to empty value") {
                        view.accessibilityIdentifier = "idA"
                        view.accessibilityIdentifier = ""
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventually(equal(("idA", "", view)))
                    }

                    it("will get notified for change from empty value to nil") {
                        view.accessibilityIdentifier = ""
                        view.accessibilityIdentifier = nil
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventually(equal(("", nil, view)))
                    }

                    it("will not get notified for change from valueA to valueA") {
                        view.accessibilityIdentifier = "idA"
                        view.accessibilityIdentifier = "idA"
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventuallyNot(equal(("idA", "idA", view)))
                    }

                    it("will not get notified for change from nil to nil") {
                        view.accessibilityIdentifier = nil
                        view.accessibilityIdentifier = nil
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventuallyNot(equal((nil, nil, view)))
                    }

                    it("will not get notified for change from empty value to empty value") {
                        view.accessibilityIdentifier = ""
                        view.accessibilityIdentifier = ""
                        expect(observer.wasViewDidUpdateIdentifierCalledWithArgs).toEventuallyNot(equal(("", "", view)))
                    }
                }
            }
        }
    }
}

private class ViewListenerObserverObject: ViewListenerObserver {

    var wasViewDidChangeSuperviewCalled = false
    var wasViewDidMoveToWindowCalled = false
    var wasViewDidGetRemovedFromSuperview = false
    // swiftlint:disable:next large_tuple
    var wasViewDidUpdateIdentifierCalledWithArgs: (from: String?, to: String?, view: UIView)?

    func viewDidChangeSuperview(_ view: UIView, identifier: String) {
        wasViewDidChangeSuperviewCalled = true
    }

    func viewDidMoveToWindow(_ view: UIView, identifier: String) {
        wasViewDidMoveToWindowCalled = true
    }

    func viewDidGetRemovedFromSuperview(_ view: UIView, identifier: String) {
        wasViewDidGetRemovedFromSuperview = true
    }

    func viewDidUpdateIdentifier(from: String?, to: String?, view: UIView) {
        wasViewDidUpdateIdentifierCalledWithArgs = (from, to, view)
    }
}
