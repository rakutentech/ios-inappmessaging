import Foundation
import Quick
import Nimble
import class UIKit.UIView

@testable import RInAppMessaging

class TooltipEventSenderSpec: QuickSpec {

    override func spec() {
        describe("TooltipEventSender") {

            var eventSender: TooltipEventSender!
            var iamModule: InAppMessagingModuleMock!
            var viewListener: ViewListenerMock!
            var campaignRepository: CampaignRepositoryMock!

            beforeEach {
                viewListener = ViewListenerMock()
                iamModule = InAppMessagingModuleMock()
                campaignRepository = CampaignRepositoryMock()
                eventSender = TooltipEventSender(viewListener: viewListener,
                                             campaignRepository: campaignRepository)
                RInAppMessaging.setModule(iamModule)
            }

            afterEach {
                RInAppMessaging.setModule(nil)
            }

            context("when calling didUpdateCampaignList") {

                it("will iterate over displayed views") {
                    eventSender.didUpdateCampaignList()
                    expect(viewListener.wasIterateOverDisplayedViewsCalled).to(beTrue())
                }

                it("will log event for matching view") {
                    let superview = UIView()
                    let view1 = UIView()
                    view1.accessibilityIdentifier = TooltipViewIdentifierMock
                    superview.addSubview(view1)
                    let view2 = UIView()
                    view2.accessibilityIdentifier = "another.id"
                    superview.addSubview(view2)
                    viewListener.displayedViews = [view1, view2]
                    campaignRepository.list = [TestHelpers.generateTooltip(id: "test")]

                    eventSender.didUpdateCampaignList()
                    expect(iamModule.loggedEvent).toEventuallyNot(beNil())
                    expect(iamModule.loggedEvent?.type).to(equal(.viewAppeared))
                    expect((iamModule.loggedEvent as? ViewAppearedEvent)?.viewIdentifier).to(equal(TooltipViewIdentifierMock))
                }
            }

            context("when calling viewDidChangeSuperview") {
                it("will not iterate over displayed views") {
                    eventSender.viewDidChangeSuperview(UIView(), identifier: "id")
                    expect(viewListener.wasIterateOverDisplayedViewsCalled).to(beFalse())
                }

                it("will log event for matching view") {
                    let superview = UIView()
                    let view = UIView()
                    view.accessibilityIdentifier = TooltipViewIdentifierMock
                    superview.addSubview(view)
                    campaignRepository.list = [TestHelpers.generateTooltip(id: "test")]

                    eventSender.viewDidChangeSuperview(view, identifier: TooltipViewIdentifierMock)
                    expect(iamModule.loggedEvent).toEventuallyNot(beNil())
                    expect(iamModule.loggedEvent?.type).to(equal(.viewAppeared))
                    expect((iamModule.loggedEvent as? ViewAppearedEvent)?.viewIdentifier).to(equal(TooltipViewIdentifierMock))
                }
            }

            context("when calling viewDidMoveToWindow") {
                it("will not iterate over displayed views") {
                    eventSender.viewDidMoveToWindow(UIView(), identifier: "id")
                    expect(viewListener.wasIterateOverDisplayedViewsCalled).to(beFalse())
                }

                it("will log event for matching view") {
                    let superview = UIView()
                    let view = UIView()
                    view.accessibilityIdentifier = TooltipViewIdentifierMock
                    superview.addSubview(view)
                    campaignRepository.list = [TestHelpers.generateTooltip(id: "test")]

                    eventSender.viewDidMoveToWindow(view, identifier: TooltipViewIdentifierMock)
                    expect(iamModule.loggedEvent).toEventuallyNot(beNil())
                    expect(iamModule.loggedEvent?.type).to(equal(.viewAppeared))
                    expect((iamModule.loggedEvent as? ViewAppearedEvent)?.viewIdentifier).to(equal(TooltipViewIdentifierMock))
                }
            }

            context("when calling viewDidUpdateIdentifier") {
                it("will not iterate over displayed views") {
                    eventSender.viewDidUpdateIdentifier(from: nil, to: "id", view: UIView())
                    expect(viewListener.wasIterateOverDisplayedViewsCalled).to(beFalse())
                }

                it("will log event for matching view") {
                    let superview = UIView()
                    let view = UIView()
                    view.accessibilityIdentifier = TooltipViewIdentifierMock
                    superview.addSubview(view)
                    campaignRepository.list = [TestHelpers.generateTooltip(id: "test")]

                    eventSender.viewDidUpdateIdentifier(from: "old-id", to: TooltipViewIdentifierMock, view: view)
                    expect(iamModule.loggedEvent).toEventuallyNot(beNil())
                    expect(iamModule.loggedEvent?.type).to(equal(.viewAppeared))
                    expect((iamModule.loggedEvent as? ViewAppearedEvent)?.viewIdentifier).to(equal(TooltipViewIdentifierMock))
                }
            }
        }
    }
}
