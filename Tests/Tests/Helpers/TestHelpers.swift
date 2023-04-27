import Foundation
import class UIKit.UIColor
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
        validatedElements.map { $0.campaign }
    }
    private(set) lazy var closure = { [unowned self] (campaign: Campaign, events: Set<Event>) in
        self.validatedElements.append(Element(campaign, events))
    }
}

// swiftlint:disable type_body_length
struct TestHelpers {

    static func generateCampaign(id: String,
                                 title: String = "testTitle",
                                 maxImpressions: Int = 1,
                                 delay: Int = 0,
                                 type: CampaignDisplayType = .modal,
                                 test: Bool = false,
                                 hasImage: Bool = false,
                                 content: Content? = nil,
                                 triggers: [Trigger]? = nil,
                                 buttons: [Button] = []) -> Campaign {
        Campaign(
            data: CampaignData(
                campaignId: id,
                maxImpressions: maxImpressions,
                type: type,
                triggers: triggers,
                isTest: test,
                infiniteImpressions: false,
                hasNoEndDate: false,
                isCampaignDismissable: true,
                messagePayload: MessagePayload(
                    title: title,
                    messageBody: "testBody",
                    header: "testHeader",
                    titleColor: "#000000",
                    headerColor: "#444444",
                    messageBodyColor: "#FAFAFA",
                    backgroundColor: "#FAFAFA",
                    frameColor: "#FF2222",
                    resource: Resource(
                        imageUrl: hasImage ? "https://www.example.com/cat.jpg" : nil,
                        cropType: .fill),
                    messageSettings: MessageSettings(
                        displaySettings: DisplaySettings(
                            orientation: .portrait,
                            slideFrom: .bottom,
                            endTimeMilliseconds: Int64.max,
                            textAlign: .fill,
                            optOut: false,
                            html: false,
                            delay: delay),
                        controlSettings: ControlSettings(
                            buttons: buttons,
                            content: content))
                )
            )
        )
    }

    static func generateTooltip(id: String,
                                title: String = "[Tooltip] title",
                                isTest: Bool = false,
                                targetViewID: String? = nil,
                                maxImpressions: Int = 2,
                                autoCloseSeconds: Int = 0,
                                redirectURL: String = "",
                                position: TooltipBodyData.Position = .topCenter,
                                triggers: [Trigger] = []) -> Campaign {
        Campaign(
            data: CampaignData(
                campaignId: id,
                maxImpressions: maxImpressions,
                type: .modal,
                triggers: triggers,
                isTest: isTest,
                infiniteImpressions: false,
                hasNoEndDate: true,
                isCampaignDismissable: true,
                messagePayload: MessagePayload(
                    title: title,
                    messageBody: """
                    {\"UIElement\" : \"\(targetViewID ?? TooltipViewIdentifierMock)\", \"position\": \"\(position.rawValue)\", \"auto-disappear\": \(autoCloseSeconds), \"redirectURL\": \"\(redirectURL)\"}
                    """, // swiftlint:disable:previous line_length
                    header: "testHeader",
                    titleColor: "color",
                    headerColor: "color2",
                    messageBodyColor: "color3",
                    backgroundColor: "#ffffff",
                    frameColor: "color5",
                    resource: Resource(
                        imageUrl: Bundle.unitTests?.url(forResource: "test-image", withExtension: "png")!.absoluteString,
                        cropType: .fill),
                    messageSettings: MessageSettings(
                        displaySettings: DisplaySettings(
                            orientation: .portrait,
                            slideFrom: .bottom,
                            endTimeMilliseconds: Int64.max,
                            textAlign: .fill,
                            optOut: false,
                            html: false,
                            delay: 0),
                        controlSettings: ControlSettings(
                            buttons: [],
                            content: nil))
                )
            )
        )
    }

    enum MockResponse {
        static func withGeneratedCampaigns(count: Int,
                                           test: Bool,
                                           delay: Int,
                                           maxImpressions: Int = 2,
                                           addContexts: Bool = false,
                                           triggers: [Trigger] = []) -> PingResponse {
            var campaigns = [Campaign]()
            // swiftlint:disable:next empty_count
            if count > 0 {
                let title = addContexts ? "[ctx] testTitle" : "testTitle"
                for i in 1...count {
                    campaigns.append(generateCampaign(
                        id: "testCampaignId\(i)",
                        title: title,
                        maxImpressions: maxImpressions,
                        delay: delay,
                        test: test,
                        triggers: triggers))
                }
            }

            return PingResponse(
                nextPingMilliseconds: Int.max,
                currentPingMilliseconds: 0,
                data: campaigns)
        }

        static func withGeneratedTooltip(uiElementIdentifier: String,
                                         maxImpressions: Int = 2,
                                         addContexts: Bool = false,
                                         triggers: [Trigger] = []) -> PingResponse {
            let title = addContexts ? "[Tooltip][ctx] testTitle" : "[Tooltip] testTitle"
            let tooltip = generateTooltip(id: "tooltip-id",
                                          title: title,
                                          targetViewID: uiElementIdentifier,
                                          triggers: triggers)

            return PingResponse(
                nextPingMilliseconds: Int.max,
                currentPingMilliseconds: 0,
                data: [tooltip])
        }

        static let stringTypeWithEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "attributeOneValue",
                                                             type: .string, operatorType: .equals)
                                        ]
                                    )])
        }()

        static let stringTypeWithNotEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "attributeOneValue",
                                                             type: .string, operatorType: .isNotEqual)
                                        ]
                                    )])
        }()

        static let intTypeWithEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123",
                                                             type: .integer, operatorType: .equals)
                                        ]
                                    )])
        }()

        static let intTypeWithNotEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123",
                                                             type: .integer, operatorType: .isNotEqual)
                                        ]
                                    )])
        }()

        static let intTypeWithGreaterThanOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123",
                                                             type: .integer, operatorType: .greaterThan)
                                        ]
                                    )])
        }()

        static let intTypeWithLessThanOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123",
                                                             type: .integer, operatorType: .lessThan)
                                        ]
                                    )])
        }()

        static let doubleTypeWithEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123.0",
                                                             type: .double, operatorType: .equals)
                                        ]
                                    )])
        }()

        static let doubleTypeWithNotEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123.0",
                                                             type: .double, operatorType: .isNotEqual)
                                        ]
                                    )])
        }()

        static let doubleTypeWithGreaterThanOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123.0",
                                                             type: .double, operatorType: .greaterThan)
                                        ]
                                    )])
        }()

        static let doubleTypeWithLessThanOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "123.0",
                                                             type: .double, operatorType: .lessThan)
                                        ]
                                    )])
        }()

        static let boolTypeWithEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "true",
                                                             type: .boolean, operatorType: .equals)
                                        ]
                                    )])
        }()

        static let boolTypeWithNotEqualOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "true",
                                                             type: .boolean, operatorType: .isNotEqual)
                                        ]
                                    )])
        }()

        static let timeTypeWithEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "1100",
                                                             type: .timeInMilliseconds, operatorType: .equals)
                                        ]
                                    )])
        }()

        static let timeTypeWithNotEqualsOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "1100",
                                                             type: .timeInMilliseconds, operatorType: .isNotEqual)
                                        ]
                                    )])
        }()

        static let timeTypeWithGreaterThanOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "1100",
                                                             type: .timeInMilliseconds, operatorType: .greaterThan)
                                        ]
                                    )])
        }()

        static let timeTypeWithLessThanOperator: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "1100",
                                                             type: .timeInMilliseconds, operatorType: .lessThan)
                                        ]
                                    )])
        }()

        static let caseInsensitiveEventName: PingResponse = {
            withGeneratedCampaigns(count: 1,
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
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "hi",
                                                             type: .string, operatorType: .equals)
                                        ]
                                    )])
        }()

        static let caseInsensitiveAttributeValue: PingResponse = {
            withGeneratedCampaigns(count: 1,
                                   test: false,
                                   delay: 0,
                                   triggers: [
                                    Trigger(
                                        type: .event,
                                        eventType: .custom,
                                        eventName: "testevent",
                                        attributes: [
                                            TriggerAttribute(name: "attributeone", value: "Hi",
                                                             type: .string, operatorType: .equals)
                                        ]
                                    )])
        }()
    }

    static func getJSONData(fileName: String) -> Data! {
        guard let bundle = Bundle.unitTests,
              let jsonURL = bundle.url(forResource: fileName, withExtension: "json") else {

            assertionFailure()
            return nil
        }

        do {
            return try Data(contentsOf: jsonURL)
        } catch {
            assertionFailure()
            return nil
        }
    }

    static func getJSONModel<T: Decodable>(fileName: String) -> T! {
        let data = getJSONData(fileName: fileName)!
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Extensions

extension NSError {
    static var emptyError: Error {
        NSError(domain: "", code: 0, userInfo: nil) as Error
    }
}

extension UIColor {
    static var blackRGB: UIColor {
        UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    static var whiteRGB: UIColor {
        UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
}

extension Result {
    func getError() -> Failure? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}

extension Trigger {
    static let loginEventTrigger = Trigger(type: .event,
                                           eventType: .loginSuccessful,
                                           eventName: "login",
                                           attributes: [])
}

extension InAppMessagingModuleConfiguration {
    static let empty = Self.init(configURLString: nil, subscriptionID: nil, isTooltipFeatureEnabled: true)

    init(subscriptionID: String?) {
        self.init(configURLString: "https://config.test", subscriptionID: subscriptionID, isTooltipFeatureEnabled: true)
    }
}
