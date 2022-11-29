import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class ConfigEndpointResponseSpec: QuickSpec {

    override func spec() {

        describe("ConfigEndpointResponse model") {
            context("when decoding JSON payload") {

                it("will be correctly created if all fields are present") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.allFields.utf8Data!)

                    expect(model).toNot(beNil())
                    expect(model?.data.rolloutPercentage).to(equal(0))
                    expect(model?.data.endpoints?.ping).toNot(beNil())
                    expect(model?.data.endpoints?.impression).toNot(beNil())
                    expect(model?.data.endpoints?.displayPermission).toNot(beNil())
                }

                it("will be correctly created if there are no endpoints") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.noEndpoints.utf8Data!)

                    expect(model).toNot(beNil())
                    expect(model?.data.rolloutPercentage).to(equal(0))
                    expect(model?.data.endpoints).to(beNil())
                }

                it("will be correctly created if endpoints field is empty") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.emptyEndpoints.utf8Data!)

                    expect(model).toNot(beNil())
                    expect(model?.data.rolloutPercentage).to(equal(0))
                    expect(model?.data.endpoints?.ping).to(beNil())
                    expect(model?.data.endpoints?.impression).to(beNil())
                    expect(model?.data.endpoints?.displayPermission).to(beNil())
                }

                it("will be correctly created if there is no ping endpoint") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.noPingEndpoint.utf8Data!)

                    expect(model).toNot(beNil())
                    expect(model?.data.rolloutPercentage).to(equal(0))
                    expect(model?.data.endpoints?.ping).to(beNil())
                    expect(model?.data.endpoints?.impression).toNot(beNil())
                    expect(model?.data.endpoints?.displayPermission).toNot(beNil())
                }

                it("will be correctly created if there is no impression endpoint") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.noImpressionEndpoint.utf8Data!)

                    expect(model).toNot(beNil())
                    expect(model?.data.rolloutPercentage).to(equal(0))
                    expect(model?.data.endpoints?.ping).toNot(beNil())
                    expect(model?.data.endpoints?.impression).to(beNil())
                    expect(model?.data.endpoints?.displayPermission).toNot(beNil())
                }

                it("will be correctly created if there is no display permission endpoint") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.noDisplayPermissionEndpoint.utf8Data!)

                    expect(model).toNot(beNil())
                    expect(model?.data.rolloutPercentage).to(equal(0))
                    expect(model?.data.endpoints?.ping).toNot(beNil())
                    expect(model?.data.endpoints?.impression).toNot(beNil())
                    expect(model?.data.endpoints?.displayPermission).to(beNil())
                }

                it("will not be correctly created if there is no rolloutPercentage flag") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.noRolloutPercentage.utf8Data!)

                    expect(model).to(beNil())
                }

                it("will not be correctly created if there is no data") {
                    let model = try? JSONDecoder().decode(ConfigEndpointResponse.self, from: Payloads.noData.utf8Data!)

                    expect(model).to(beNil())
                }
            }
        }
    }

    private enum Payloads {
        static let allFields = """
        {
          "data": {
            "rolloutPercentage": 0,
            "endpoints": {
              "ping": "https://something",
              "impression": "https://something",
              "displayPermission": "https://something"
            }
          }
        }
        """

        static let noEndpoints = """
        {
          "data": {
            "rolloutPercentage": 0
          }
        }
        """

        static let noPingEndpoint = """
        {
          "data": {
            "rolloutPercentage": 0,
            "endpoints": {
              "impression": "https://something",
              "displayPermission": "https://something"
            }
          }
        }
        """

        static let noImpressionEndpoint = """
        {
          "data": {
            "rolloutPercentage": 0,
            "endpoints": {
              "ping": "https://something",
              "displayPermission": "https://something"
            }
          }
        }
        """

        static let noDisplayPermissionEndpoint = """
        {
          "data": {
            "rolloutPercentage": 0,
            "endpoints": {
              "ping": "https://something",
              "impression": "https://something"
            }
          }
        }
        """

        static let noRolloutPercentage = """
        {
          "data": {
            "endpoints": {
              "ping": "https://something",
              "impression": "https://something",
              "displayPermission": "https://something"
            }
          }
        }
        """

        static let emptyEndpoints = """
        {
          "data": {
            "rolloutPercentage": 0,
            "endpoints": { }
          }
        }
        """

        static let noData = "{ }"
    }
}

private extension String {
    var utf8Data: Data? {
        data(using: .utf8)
    }
}
