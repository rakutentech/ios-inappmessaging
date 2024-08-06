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

            it("should always set impressionsLeft to 1 for test campaigns (ignore infiniteImpressions and maxImpressions)") {
                let pingResponse: PingResponse = TestHelpers.getJSONModel(fileName: "ping_success")
                let campaign = pingResponse.data[2]
                expect(campaign.impressionsLeft).to(equal(1))
            }

            it("should return true for isOutdated even if endTimeMillis is in the past") {
                let campaign = MockedCampaigns.outdatedCampaignWithNoEndDate
                expect(campaign.isOutdated).to(beFalse())
            }

            it("should decode legacy (cached) data by setting default values in new properties") {
                let pingResponse: PingResponse? = TestHelpers.getJSONModel(fileName: "legacy_ping")
                let campaign = pingResponse?.data.first
                expect(pingResponse).toNot(beNil())
                expect(campaign).toNot(beNil())

                expect(campaign?.data.infiniteImpressions).to(beFalse())
                expect(campaign?.data.hasNoEndDate).to(beFalse())
                expect(campaign?.data.isCampaignDismissable).to(beTrue())
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

        describe("Tooltip") {
            context("isTooltip") {

                it("will return true if body contains valid JSON data") {
                    let tooltip = generateTooltip(title: "[Tooltip] t1",
                                                  imageURL: "image.url",
                                                  body: """
                        {\"UIElement\" : \"view\", \"position\": \"top-center\", \"auto-disappear\": 2, \"redirectURL\": \"url\"}
                        """)
                    expect(tooltip.isTooltip).to(beTrue())
                }

                it("will return true if body contains only required JSON data") {
                    let tooltip = generateTooltip(title: "[Tooltip] t1",
                                                  imageURL: "image.url",
                                                  body: """
                        {\"UIElement\" : \"view\", \"position\": \"top-center\"}
                        """)
                    expect(tooltip.isTooltip).to(beTrue())
                }

                it("will return false if there's no imageUrl") {
                    let tooltip = generateTooltip(title: "[Tooltip] t1",
                                                  imageURL: nil,
                                                  body: """
                        {\"UIElement\" : \"view\", \"position\": \"top-center\"}
                        """)
                    expect(tooltip.isTooltip).to(beFalse())
                }

                it("will return false if title doesn't start with '[Tooltip]'") {
                    let tooltip = generateTooltip(title: "[ctx] t1",
                                                  imageURL: "image.url",
                                                  body: """
                        {\"UIElement\" : \"view\", \"position\": \"top-center\"}
                        """)
                    expect(tooltip.isTooltip).to(beFalse())
                }

                it("will accept '[Tooltip]' prefix in any form (case insensitive)") {
                    ["[ToolTip]", "[tooltip]", "[tOOltip]"].forEach { titlePrefix in
                        let tooltip = generateTooltip(title: "\(titlePrefix) t1",
                                                      imageURL: "image.url",
                                                      body: """
                            {\"UIElement\" : \"view\", \"position\": \"top-center\"}
                            """)
                        expect(tooltip.isTooltip).to(beTrue())
                    }
                }

                it("will return false if body doesn't contain valid JSON data") {
                    let tooltip = generateTooltip(title: "[Tooltip] t1",
                                                  imageURL: "image.url",
                                                  body: "\"UIElement\" : \"view\"")
                    expect(tooltip.isTooltip).to(beFalse())
                }

                it("will return false if body doesn't contain required JSON fields") {
                    let tooltip = generateTooltip(title: "[Tooltip] t1",
                                                  imageURL: "image.url",
                                                  body: "{\"UIElement\" : \"view\"}")
                    expect(tooltip.isTooltip).to(beFalse())
                }
            }
        }

        func generateTooltip(title: String,
                             imageURL: String?,
                             body: String) -> Campaign {
            Campaign(
                data: CampaignData(
                    campaignId: "id",
                    maxImpressions: 1,
                    type: .modal,
                    triggers: [],
                    isTest: false,
                    infiniteImpressions: false,
                    hasNoEndDate: true,
                    isCampaignDismissable: true,
                    messagePayload: MessagePayload(
                        title: title,
                        messageBody: body,
                        header: "testHeader",
                        titleColor: "color",
                        headerColor: "color2",
                        messageBodyColor: "color3",
                        backgroundColor: "#ffffff",
                        frameColor: "color5",
                        resource: Resource(
                            imageUrl: imageURL,
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
                    ),
                    customJson: nil
                )
            )
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
            ),
            customJson: nil
        )
    )
}
