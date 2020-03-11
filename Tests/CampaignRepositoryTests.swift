import Quick
import Nimble
@testable import RInAppMessaging

class CampaignRepositoryTests: QuickSpec {

    override func spec() {
        describe("CampaignRepository") {

            var campaignRepository: CampaignRepository!
            var firstPersistedCampaign: Campaign? {
                return campaignRepository.list.first
            }

            func insertRandomCampaigns() {
                let campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0)
            }

            beforeEach {
                campaignRepository = CampaignRepository()
            }

            context("when syncing") {

                it("will add new campaigns to the list") {
                    insertRandomCampaigns()
                    let newCampaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                    campaignRepository.syncWith(list: newCampaigns, timestampMilliseconds: 0)
                    expect(campaignRepository.list).to(contain(newCampaigns))
                }

                it("will remove not existing campaigns") {
                    var campaigns = TestHelpers.MockResponse.withGeneratedCampaigns(count: 2, test: false, delay: 1).data
                    campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0)
                    expect(campaignRepository.list).to(haveCount(2))

                    campaigns.removeLast()
                    campaignRepository.syncWith(list: campaigns, timestampMilliseconds: 0)
                    expect(campaignRepository.list).to(haveCount(1))
                }

                it("will persist impressionsLeft value if maxImpressions number is bigger") {
                    let campaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                test: false,
                                                                delay: 0,
                                                                maxImpressions: 3)
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    _ = campaignRepository.decrementImpressionsLeftInCampaign(campaign)
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                    expect(firstPersistedCampaign?.data.maxImpressions).to(equal(3))
                }

                it("will update impressionsLeft value if maxImpressions number is smaller") {
                    let campaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                test: false,
                                                                delay: 0,
                                                                maxImpressions: 3)
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    let updatedCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                       test: false,
                                                                       delay: 0,
                                                                       maxImpressions: 1)
                    campaignRepository.syncWith(list: [updatedCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(1))
                    expect(firstPersistedCampaign?.data.maxImpressions).to(equal(1))
                }

                it("will persist isOptedOut value") {
                    let campaign = TestHelpers.generateCampaign(id: "testOptedOut",
                                                                test: false,
                                                                delay: 0,
                                                                maxImpressions: 3)
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    _ = campaignRepository.optOutCampaign(campaign)
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }
            }

            context("when optOutCampaign is called") {

                it("will mark campaign as opted out") {
                    let campaign = TestHelpers.generateCampaign(id: "testOptedOut",
                                                                test: false,
                                                                delay: 0,
                                                                maxImpressions: 3)
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign).to(equal(campaign))
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    _ = campaignRepository.optOutCampaign(campaign)
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }
            }

            context("when decrementImpressionsLeftInCampaign is called") {

                let campaign = TestHelpers.generateCampaign(id: "testImpressionsLeft",
                                                            test: false,
                                                            delay: 0,
                                                            maxImpressions: 3)

                it("will decrement campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign).to(equal(campaign))
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    _ = campaignRepository.decrementImpressionsLeftInCampaign(campaign)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))
                }

                it("will not decrement campaign data's impressions") {
                    campaignRepository.syncWith(list: [campaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign).to(equal(campaign))
                    expect(firstPersistedCampaign?.data.maxImpressions).to(equal(3))

                    _ = campaignRepository.decrementImpressionsLeftInCampaign(campaign)
                    expect(firstPersistedCampaign?.data.maxImpressions).to(equal(3))
                }
            }
        }
    }
}
