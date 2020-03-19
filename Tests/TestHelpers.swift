@testable import RInAppMessaging

class ValidatorHandler {
    struct Element: Equatable {
        let campaign: Campaign
        let events: Set<Event>

        init(_ campaign: Campaign, _ events: Set<Event>) {
            self.campaign = campaign
            self.events = events
        }
    }

    var validatedElements = [Element]()
    var validatedCampaigns: [Campaign] {
        return validatedElements.map { $0.campaign }
    }
    private(set) lazy var closure = { [unowned self] (campaign: Campaign, events: Set<Event>) in
        self.validatedElements.append(Element(campaign, events))
    }
}

//swiftlint:disable:next type_body_length
struct TestHelpers {

    static func generateCampaign(id: String,
                                 test: Bool,
                                 delay: Int,
                                 maxImpressions: Int,
                                 triggers: [Trigger]? = nil) -> Campaign {
        return Campaign(
            data: CampaignData(
                campaignId: id,
                maxImpressions: maxImpressions,
                type: 1,
                triggers: triggers,
                isTest: test,
                messagePayload: MessagePayload(
                    title: "testTitle",
                    messageBody: "testBody",
                    messageLowerBody: "testLowerBody",
                    header: "testHeader",
                    titleColor: "color",
                    headerColor: "color2",
                    messageBodyColor: "color3",
                    backgroundColor: "color4",
                    frameColor: "color5",
                    resource: Resource(
                        assetsUrl: nil,
                        imageUrl: nil,
                        cropType: 1),
                    messageSettings: MessageSettings(
                        displaySettings: DisplaySettings(
                            orientation: 1,
                            slideFrom: .bottom,
                            endTimeMillis: Int64.max,
                            textAlign: 1,
                            optOut: false,
                            html: false,
                            delay: delay),
                        controlSettings: nil)
                )
            )
        )
    }

    static func generateCampaign(id: String,
                                 content: Content? = nil,
                                 buttons: [Button]? = nil) -> Campaign {
        return Campaign(
            data: CampaignData(
                campaignId: id,
                maxImpressions: 1,
                type: 1,
                triggers: nil,
                isTest: false,
                messagePayload: MessagePayload(
                    title: "testTitle",
                    messageBody: "testBody",
                    messageLowerBody: "testLowerBody",
                    header: "testHeader",
                    titleColor: "color",
                    headerColor: "color2",
                    messageBodyColor: "color3",
                    backgroundColor: "color4",
                    frameColor: "color5",
                    resource: Resource(
                        assetsUrl: nil,
                        imageUrl: nil,
                        cropType: 1),
                    messageSettings: MessageSettings(
                        displaySettings: DisplaySettings(
                            orientation: 1,
                            slideFrom: .bottom,
                            endTimeMillis: Int64.max,
                            textAlign: 1,
                            optOut: false,
                            html: false,
                            delay: 0),
                        controlSettings: ControlSettings(
                            buttons: buttons,
                            content: content))
                )
            )
        )
    }

    enum MockResponse {

        static func withGeneratedCampaigns(count: Int,
                                           test: Bool,
                                           delay: Int,
                                           triggers: [Trigger]? = nil) -> PingResponse {
            var campaigns = [Campaign]()
            for i in 1...count {
                campaigns.append(generateCampaign(
                    id: "testCampaignId\(i)",
                    test: test,
                    delay: delay,
                    maxImpressions: 2,
                    triggers: triggers))
            }

            return PingResponse(
                nextPingMillis: 0,
                currentPingMillis: 0,
                data: campaigns)
        }

        static let stringTypeWithEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "attributeOneValue",
                                                                     type: .string, operator: .equals)
                                                ]
                                            )])
        }()

        static let stringTypeWithNotEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "attributeOneValue",
                                                                     type: .string, operator: .isNotEqual)
                                                ]
                                            )])
        }()

        static let intTypeWithEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123",
                                                                     type: .integer, operator: .equals)
                                                ]
                                            )])
        }()

        static let intTypeWithNotEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123",
                                                                     type: .integer, operator: .isNotEqual)
                                                ]
                                            )])
        }()

        static let intTypeWithGreaterThanOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123",
                                                                     type: .integer, operator: .greaterThan)
                                                ]
                                            )])
        }()

        static let intTypeWithLessThanOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123",
                                                                     type: .integer, operator: .lessThan)
                                                ]
                                            )])
        }()

        static let doubleTypeWithEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123.0",
                                                                     type: .double, operator: .equals)
                                                ]
                                            )])
        }()

        static let doubleTypeWithNotEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123.0",
                                                                     type: .double, operator: .isNotEqual)
                                                ]
                                            )])
        }()

        static let doubleTypeWithGreaterThanOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123.0",
                                                                     type: .double, operator: .greaterThan)
                                                ]
                                            )])
        }()

        static let doubleTypeWithLessThanOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "123.0",
                                                                     type: .double, operator: .lessThan)
                                                ]
                                            )])
        }()

        static let boolTypeWithEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "true",
                                                                     type: .boolean, operator: .equals)
                                                ]
                                            )])
        }()

        static let boolTypeWithNotEqualOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "true",
                                                                     type: .boolean, operator: .isNotEqual)
                                                ]
                                            )])
        }()

        static let timeTypeWithEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "1100",
                                                                     type: .timeInMilli, operator: .equals)
                                                ]
                                            )])
        }()

        static let timeTypeWithNotEqualsOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "1100",
                                                                     type: .timeInMilli, operator: .isNotEqual)
                                                ]
                                            )])
        }()

        static let timeTypeWithGreaterThanOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "1100",
                                                                     type: .timeInMilli, operator: .greaterThan)
                                                ]
                                            )])
        }()

        static let timeTypeWithLessThanOperator: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "1100",
                                                                     type: .timeInMilli, operator: .lessThan)
                                                ]
                                            )])
        }()

        static let caseInsensitiveEventName: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                ]
                                            )])
        }()

        static let caseInsensitiveAttributeName: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "hi",
                                                                     type: .string, operator: .equals)
                                                ]
                                            )])
        }()

        static let caseSensitiveAttributeValue: PingResponse = {
            return withGeneratedCampaigns(count: 1,
                                          test: false,
                                          delay: 0,
                                          triggers: [
                                            Trigger(
                                                type: .event,
                                                eventType: .custom,
                                                eventName: "testevent",
                                                attributes: [
                                                    TriggerAttribute(name: "attributeone", value: "Hi",
                                                                     type: .string, operator: .equals)
                                                ]
                                            )])
        }()
    }
}

extension NSError {
    static var emptyError: Error {
        return NSError(domain: "", code: 0, userInfo: nil) as Error
    }
}

extension UIColor {
    static var blackRGB: UIColor {
        return UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    static var whiteRGB: UIColor {
        return UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
}
