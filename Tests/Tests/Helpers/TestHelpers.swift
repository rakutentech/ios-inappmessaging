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
        return validatedElements.map { $0.campaign }
    }
    private(set) lazy var closure = { [unowned self] (campaign: Campaign, events: Set<Event>) in
        self.validatedElements.append(Element(campaign, events))
    }
}

// swiftlint:disable:next type_body_length
struct TestHelpers {

    static func generateCampaign(id: String,
                                 title: String = "testTitle",
                                 maxImpressions: Int = 1,
                                 delay: Int = 0,
                                 type: CampaignDisplayType = .modal,
                                 test: Bool = false,
                                 hasImage: Bool = false,
                                 content: Content? = nil,
                                 triggers: [Trigger] = [],
                                 buttons: [Button] = []) -> Campaign {
        return Campaign(
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
                                                                     type: .timeInMilliseconds, operator: .equals)
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
                                                                     type: .timeInMilliseconds, operator: .isNotEqual)
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
                                                                     type: .timeInMilliseconds, operator: .greaterThan)
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
                                                                     type: .timeInMilliseconds, operator: .lessThan)
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

        static let caseInsensitiveAttributeValue: PingResponse = {
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
