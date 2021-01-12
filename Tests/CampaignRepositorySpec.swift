import Quick
import Nimble
@testable import RInAppMessaging

class CampaignRepositorySpec: QuickSpec {

    override func spec() {
        describe("CampaignRepository") {

            var campaignRepository: CampaignRepository!
            var firstPersistedCampaign: Campaign? {
                return campaignRepository.list.first
            }
            let testCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                            test: false,
                                                            delay: 0,
                                                            maxImpressions: 3)

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

                it("will override impressionsLeft value even if maxImpressions number is bigger") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(testCampaign)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(2))

                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))
                }

                it("will persist isOptedOut value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    campaignRepository.optOutCampaign(testCampaign)
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }
            }

            context("when optOutCampaign is called") {

                it("will mark campaign as opted out") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.isOptedOut).to(beFalse())

                    campaignRepository.optOutCampaign(testCampaign)
                    expect(firstPersistedCampaign?.isOptedOut).to(beTrue())
                }
            }

            context("when decrementImpressionsLeftInCampaign is called") {

                it("will decrement campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    let impressionsLeft = firstPersistedCampaign?.impressionsLeft ?? 0

                    campaignRepository.decrementImpressionsLeftInCampaign(testCampaign)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(impressionsLeft - 1))
                }

                it("will not decrement campaign's impressionsLeft value if it's already 0") {
                    let testCampaign = TestHelpers.generateCampaign(id: "testImpressions",
                                                                    test: false,
                                                                    delay: 0,
                                                                    maxImpressions: 0)
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    campaignRepository.decrementImpressionsLeftInCampaign(testCampaign)

                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(0))
                }
            }

            context("when incrementImpressionsLeftInCampaign is called") {

                it("will increment campaign's impressionsLeft value") {
                    campaignRepository.syncWith(list: [testCampaign], timestampMilliseconds: 0)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(3))

                    campaignRepository.incrementImpressionsLeftInCampaign(testCampaign)
                    expect(firstPersistedCampaign?.impressionsLeft).to(equal(4))
                }
            }
        }
    }
}
