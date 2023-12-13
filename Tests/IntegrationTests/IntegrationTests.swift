import XCTest

#if SWIFT_PACKAGE
import class RSDKUtilsMain.TypedDependencyManager
#else
import class RSDKUtils.TypedDependencyManager
#endif

@testable import RInAppMessaging

class IntegrationTests: XCTestCase {

    private enum Constants {
        static let requestTimeout: TimeInterval = 10.0
    }

    static var testQueue: DispatchQueue!
    static var dependencyManager: TypedDependencyManager!

    var testQueue: DispatchQueue {
        IntegrationTests.testQueue
    }
    var dependencyManager: TypedDependencyManager {
        IntegrationTests.dependencyManager
    }

    override class func setUp() {
        testQueue = DispatchQueue(label: "IAM.IntegrationTests", qos: .utility)
        dependencyManager = TypedDependencyManager()

        guard let configURLString = BundleInfo.inAppConfigurationURL, let configURL = URL(string: configURLString) else {
            assertionFailure("Invalid configuration URL in Info.plist")
            return
        }
        dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager, configURL: configURL))
        dependencyManager.resolve(type: ConfigurationRepositoryType.self)?
            .saveIAMModuleConfiguration(InAppMessagingModuleConfiguration(configURLString: configURLString,
                                                                          subscriptionID: BundleInfo.inAppSubscriptionId,
                                                                          isTooltipFeatureEnabled: true))
    }

    func test1Config() throws {
        let expectation = XCTestExpectation(description: "GetConfig request")

        testQueue.async {
            let configRepo = self.dependencyManager.resolve(type: ConfigurationRepositoryType.self)
            let service = self.dependencyManager.resolve(type: ConfigurationServiceType.self)
            XCTAssertNotNil(service)

            let result = service?.getConfigData()
            let response: ConfigEndpointData?
            do {
                response = try result?.get()
                configRepo?.saveRemoteConfiguration(response!)
            } catch {
                XCTFail("Couldn't get a response from configuration service. Error: \(error)")
                response = nil
            }
            XCTAssertNotNil(response)
            XCTAssertNotNil(response?.rolloutPercentage)
            XCTAssertNotNil(response?.endpoints?.ping)
            XCTAssertNotNil(response?.endpoints?.displayPermission)
            XCTAssertNotNil(response?.endpoints?.impression)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.requestTimeout)
    }

    func test2Ping() throws {
        let expectation = XCTestExpectation(description: "Ping request")

        testQueue.async {
            let service = self.dependencyManager.resolve(type: PingServiceType.self)
            XCTAssertNotNil(service)

            let result = service?.ping()
            let response: PingResponse?
            do {
                response = try result?.get()
            } catch {
                XCTFail("Couldn't get a response from message mixer service. Error: \(error)")
                response = nil
            }
            XCTAssertNotNil(response)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.requestTimeout)
    }
}
