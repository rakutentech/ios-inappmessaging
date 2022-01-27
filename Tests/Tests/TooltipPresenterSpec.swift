import Quick
import Nimble
@testable import RInAppMessaging

class TooltipPresenterSpec: QuickSpec {

    override func spec() {
        let tooltip = TestHelpers.generateTooltip(id: "test")

        var presenter: TooltipPresenter!
        var impressionService: ImpressionServiceMock!

        beforeEach {
            impressionService = ImpressionServiceMock()
            presenter = TooltipPresenter(impressionService: impressionService)
        }

        describe("TooltipPresenter") {

            context("when calling set()") {

                it("will setup associated view") {
                    let view = TooltipViewMock()
                    let image = UIImage()
                    presenter.set(view: view, dataModel: tooltip, image: image)

                    expect(view.setupModel).toNot(beNil())
                    expect(view.setupModel?.backgroundColor).to(equal(UIColor(hexString: "#ffffff")))
                    expect(view.setupModel?.image).to(beIdenticalTo(image))
                    expect(view.setupModel?.position).to(equal(tooltip.tooltipData?.bodyData.position))
                }

                it("will set tooltip property") {
                    presenter.set(view: TooltipViewMock(), dataModel: tooltip, image: UIImage())
                    expect(presenter.tooltip).to(equal(tooltip))
                }

                it("will log display impression") {
                    presenter.set(view: TooltipViewMock(), dataModel: tooltip, image: UIImage())
                    expect(presenter.impressions).to(haveCount(1))
                    expect(presenter.impressions.first?.type).to(equal(.impression))
                }
            }

            context("when calling didTapExitButton()") {

                beforeEach {
                    presenter.set(view: TooltipViewMock(), dataModel: tooltip, image: UIImage())
                }

                it("will call onClose") {
                    var wasOnCloseCalled = false
                    presenter.onClose = {
                        wasOnCloseCalled = true
                    }
                    presenter.didTapExitButton()
                    expect(wasOnCloseCalled).to(beTrue())
                }

                it("will log exit impression") {
                    presenter.didTapExitButton()
                    expect(impressionService.sentImpressions?.list.last).to(equal(.exit))
                }

                it("will send impressions") {
                    presenter.didTapExitButton()
                    expect(impressionService.sentImpressions).toNot(beNil())
                }
            }

            context("when calling didTapImage()") {

                beforeEach {
                    let tooltip = TestHelpers.generateTooltip(id: "test-url", redirectURL: "url")
                    presenter.set(view: TooltipViewMock(), dataModel: tooltip, image: UIImage())
                }

                it("will call onClose") {
                    var wasOnCloseCalled = false
                    presenter.onClose = {
                        wasOnCloseCalled = true
                    }
                    presenter.didTapImage()
                    expect(wasOnCloseCalled).to(beTrue())
                }

                it("will log clickContent impression") {
                    presenter.didTapImage()
                    expect(impressionService.sentImpressions?.list.last).to(equal(.clickContent))
                }

                it("will send impressions") {
                    presenter.didTapImage()
                    expect(impressionService.sentImpressions).toNot(beNil())
                }

                context("there is no redirect URL") {

                    beforeEach {
                        presenter.set(view: TooltipViewMock(), dataModel: tooltip, image: UIImage())
                    }

                    it("will not call onClose") {
                        var wasOnCloseCalled = false
                        presenter.onClose = {
                            wasOnCloseCalled = true
                        }
                        presenter.didTapImage()
                        expect(wasOnCloseCalled).to(beFalse())
                    }

                    it("will not log clickContent impression") {
                        presenter.didTapImage()
                        expect(presenter.impressions.last?.type).toNot(equal(.clickContent))
                    }

                    it("will not send impressions") {
                        presenter.didTapImage()
                        expect(impressionService.sentImpressions).to(beNil())
                    }
                }
            }
        }
    }
}
