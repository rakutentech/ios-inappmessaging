import Foundation

/// Pre-defined event that is used to signal the success of a purchase action.
@objc public class PurchaseSuccessfulEvent: Event {

    private enum Keys {
        static let purchaseAmount = "purchaseAmountMicros"
        static let numberOfItems = "numberOfItems"
        static let currencyCode = "currencyCode"
        static let itemIdList = "itemIdList"
    }

    var purchaseAmount = -1
    var numberOfItems = -1
    var currencyCode = "UNKNOWN"
    var itemList = [String]()

    /// For broadcasting to RAT SDK. 'eventType' field will be removed.
    override var analyticsParameters: [String: Any] {
        [
            "eventName": super.name,
            "timestamp": super.timestamp,
            Keys.purchaseAmount: self.purchaseAmount,
            Keys.numberOfItems: self.numberOfItems,
            Keys.currencyCode: self.currencyCode,
            Keys.itemIdList: self.itemList
        ]
    }

    var customAttributes: [CustomAttribute] {
        [
            CustomAttribute(withKeyName: Keys.purchaseAmount, withIntValue: self.purchaseAmount),
            CustomAttribute(withKeyName: Keys.numberOfItems, withIntValue: self.numberOfItems),
            CustomAttribute(withKeyName: Keys.currencyCode, withStringValue: self.currencyCode),
            CustomAttribute(withKeyName: Keys.itemIdList, withStringValue: self.itemList.joined(separator: "|"))
        ]
    }

    @objc
    public init() {
        super.init(type: EventType.purchaseSuccessful,
                   name: Constants.Event.purchaseSuccessful)
    }

    init(
        withPurchaseAmount purchaseAmount: Int,
        withNumberOfItems numberOfItems: Int,
        withCurrencyCode currencyCode: String,
        withItems itemList: [String],
        timestamp: Int64) {

            self.purchaseAmount = purchaseAmount
            self.numberOfItems = numberOfItems
            self.currencyCode = currencyCode
            self.itemList = itemList

            super.init(type: EventType.purchaseSuccessful,
                       name: Constants.Event.purchaseSuccessful,
                       timestamp: timestamp)
    }

    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }

    @objc @discardableResult
    public func setPurchaseAmount(_ purchaseAmount: Int) -> PurchaseSuccessfulEvent {
        self.purchaseAmount = purchaseAmount
        return self
    }

    @objc @discardableResult
    public func setNumberOfItems(_ numberOfItems: Int) -> PurchaseSuccessfulEvent {
        self.numberOfItems = numberOfItems
        return self
    }

    @objc @discardableResult
    public func setCurrencyCode(_ currencyCode: String) -> PurchaseSuccessfulEvent {
        self.currencyCode = currencyCode
        return self
    }

    @objc @discardableResult
    public func setItemList(_ itemList: [String]) -> PurchaseSuccessfulEvent {
        self.itemList = itemList
        return self
    }

    override func getAttributeMap() -> [String: CustomAttribute] {
        [
            Keys.purchaseAmount: CustomAttribute(withKeyName: Keys.purchaseAmount, withIntValue: self.purchaseAmount),
            Keys.numberOfItems: CustomAttribute(withKeyName: Keys.numberOfItems, withIntValue: self.numberOfItems),
            Keys.currencyCode: CustomAttribute(withKeyName: Keys.currencyCode, withStringValue: self.currencyCode),
            Keys.itemIdList: CustomAttribute(withKeyName: Keys.itemIdList, withStringValue: self.itemList.joined(separator: "|"))
        ]
    }
}
