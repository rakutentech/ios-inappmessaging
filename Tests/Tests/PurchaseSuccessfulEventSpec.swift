import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class PurchaseSuccessfulEventSpec: QuickSpec {
    override func spec() {
        let purchaseSuccessfulEvent = PurchaseSuccessfulEvent(withPurchaseAmount: 100, withNumberOfItems: 10,
                                                              withCurrencyCode: "Yen", withItems: ["event"], timestamp: 30)
        describe("PurchaseSuccessfulEvent") {
            context("PurchaseSuccessfulEvent.analyticsParameters") {
                it("will return dictionary with values") {
                    expect(purchaseSuccessfulEvent.analyticsParameters).toNot(beNil())
                    if let eventName = purchaseSuccessfulEvent.analyticsParameters["eventName"] as? String {
                        expect(eventName).to(equal("purchase_successful"))
                    }
                }
            }
            context("PurchaseSuccessfulEvent.customAttributes") {
                it("will return string array of custom attribute values") {
                    print(purchaseSuccessfulEvent.customAttributes)
                    expect(purchaseSuccessfulEvent.customAttributes).toNot(beNil())
                }
            }
            context("PurchaseSuccessfulEvent.setPurchaseAmount") {
                it("will return the purchase amount") {
                    purchaseSuccessfulEvent.setPurchaseAmount(30)
                    expect(purchaseSuccessfulEvent.purchaseAmount).to(equal(30))
                }
            }
            context("PurchaseSuccessfulEvent.setNumberOfItems") {
                it("will return the number of items") {
                    purchaseSuccessfulEvent.setNumberOfItems(45)
                    expect(purchaseSuccessfulEvent.numberOfItems).to(equal(45))
                }
            }
            context("PurchaseSuccessfulEvent.setCurrencyCode") {
                it("will return currency code") {
                    purchaseSuccessfulEvent.setCurrencyCode("Dollar")
                    expect(purchaseSuccessfulEvent.currencyCode).to(equal("Dollar"))
                }
            }
            context("PurchaseSuccessfulEvent.setItemList") {
                it("will return itemList") {
                    purchaseSuccessfulEvent.setItemList(["item"])
                    expect(purchaseSuccessfulEvent.itemList.count).to(equal(1))
                }
            }
            context("PurchaseSuccessfulEvent.getAttributeMap") {
                it("will return non empty dictionary with custom attributes ") {
                    let purchaseEvent = PurchaseSuccessfulEvent()
                    expect(purchaseEvent.getAttributeMap()).toNot(beNil())
                }
            }
        }
    }
}
