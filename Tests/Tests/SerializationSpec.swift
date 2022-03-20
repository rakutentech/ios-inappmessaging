import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class SerializationSpec: QuickSpec {

    override func spec() {

        describe("User Identifier") {
            it("should serialize with correct property names") {
                let identifier = UserIdentifier(type: .idTrackingIdentifier, identifier: "TheUserID")
                let encoder = JSONEncoder()

                let encodedData = try? encoder.encode(identifier)
                expect(encodedData).toNot(beNil())
                let encodedString = String(data: encodedData!, encoding: .utf8)
                expect(encodedString).to(equal(#"{"id":"TheUserID","type":2}"#))
            }
        }

        describe("Campaign model") {

            it("should set impressionsLeft to Int.max if infiniteImpressions is true") {
                let pingResponse: PingResponse = TestHelpers.getJSONModel(fileName: "ping_success")
                let campaign = pingResponse.data[0]
                expect(campaign.impressionsLeft).to(equal(Int.max))
            }

            it("should return true for isOutdated even if endTimeMillis is in the past") {
                let campaign = MockedCampaigns.outdatedCampaignWithNoEndDate
                expect(campaign.isOutdated).to(beFalse())
            }

            context("When parsing title for contexts") {

                it("will return empty array if there are no contexts") {
                    let campaign = TestHelpers.generateCampaign(id: "id", title: "title")
                    expect(campaign.contexts).to(beEmpty())
                }

                it("will properly read context when it is the only string content") {
                    let campaign = TestHelpers.generateCampaign(id: "id", title: "[ctx]")
                    expect(campaign.contexts).to(elementsEqual(["ctx"]))
                }

                it("will properly read one context") {
                    let campaign = TestHelpers.generateCampaign(id: "id", title: "[ctx] title")
                    expect(campaign.contexts).to(elementsEqual(["ctx"]))
                }

                it("will properly read multiple contexts") {
                    let campaign = TestHelpers.generateCampaign(id: "id", title: "[ctx1] [ctx2][ctx3] title")
                    expect(campaign.contexts).to(elementsEqual(["ctx1", "ctx2", "ctx3"]))
                }

                it("will properly read multiple contexts separated with characters") {
                    let campaign = TestHelpers.generateCampaign(id: "id", title: "[ctx A]~~[ctx B]ab ab[ctx C]")
                    expect(campaign.contexts).to(elementsEqual(["ctx A", "ctx B", "ctx C"]))
                }

                it("will ignore invalid contexts") {
                    let campaign = TestHelpers.generateCampaign(id: "id", title: "[ctx] [ctxbad title")
                    expect(campaign.contexts).to(elementsEqual(["ctx"]))
                }

                it("will properly read context even if there are invalid ones") {
                    let campaign = TestHelpers.generateCampaign(id: "id", title: "ctxbad] title [ctx]")
                    expect(campaign.contexts).to(elementsEqual(["ctx"]))
                }
            }
        }

        describe("Triggers") {

            context("when parsing custom triggers with attributes") {

                let json = #"""
                {
                    "type": 1,
                    "eventType": 4,
                    "eventName": "Custom EVENT",
                    "attributes": [
                        {
                            "name": "aName1",
                            "value": "VaLUe4",
                            "type": 1,
                            "operator": 1
                        }
                    ]
                }
                """#
                let trigger: Trigger! = try? JSONDecoder().decode(Trigger.self, from: json.data(using: .utf8)!)

                it("should have lowercased trigger name") {
                    expect(trigger.eventName) == "custom event"
                }

                it("should have lowercased attribute name") {
                    expect(trigger.attributes[0].name) == "aname1"
                }

                it("should have lowercased trigger value") {
                    expect(trigger.attributes[0].value) == "value4"
                }
            }
        }
    }
}

private enum MockedCampaigns {
    static let outdatedCampaignWithNoEndDate = Campaign(
        data: CampaignData(
            campaignId: "test",
            maxImpressions: 2,
            type: .modal,
            triggers: [
                Trigger(
                    type: .event,
                    eventType: .loginSuccessful,
                    eventName: "testevent",
                    attributes: []
                )
            ],
            isTest: false,
            infiniteImpressions: false,
            hasNoEndDate: true,
            isCampaignDismissable: true,
            messagePayload: MessagePayload(
                title: "testTitle",
                messageBody: "testBody",
                header: "testHeader",
                titleColor: "#000000",
                headerColor: "#444444",
                messageBodyColor: "#FAFAFA",
                backgroundColor: "#FAFAFA",
                frameColor: "#FF2222",
                resource: Resource(
                    imageUrl: nil,
                    cropType: .fill),
                messageSettings: MessageSettings(
                    displaySettings: DisplaySettings(
                        orientation: .portrait,
                        slideFrom: .bottom,
                        endTimeMilliseconds: 0,
                        textAlign: .fill,
                        optOut: false,
                        html: false,
                        delay: 0),
                    controlSettings: ControlSettings(buttons: [], content: nil))
            )
        ))
}
