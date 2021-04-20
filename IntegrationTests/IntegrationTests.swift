import XCTest

@testable import RInAppMessaging

class IntegrationTests: XCTestCase {

    private enum Constants {
        static let requestTimeout: TimeInterval = 10.0
    }

    static var testQueue: DispatchQueue!
    static var dependencyManager: DependencyManager!

    var testQueue: DispatchQueue {
        return IntegrationTests.testQueue
    }
    var dependencyManager: DependencyManager {
        return IntegrationTests.dependencyManager
    }

    override class func setUp() {
        testQueue = DispatchQueue(label: "IAM.IntegrationTests", qos: .utility)
        dependencyManager = DependencyManager()
        dependencyManager.appendContainer(MainContainerFactory.create(dependencyManager: dependencyManager))
    }

    func test1Config() throws {
        let expectation = XCTestExpectation(description: "GetConfig request")

        testQueue.async {
            let configRepo = self.dependencyManager.resolve(type: ConfigurationRepositoryType.self)
            let service = self.dependencyManager.resolve(type: ConfigurationServiceType.self)
            XCTAssertNotNil(service)

            let result = service?.getConfigData()
            let response: ConfigData?
            do {
                response = try result?.get()
                configRepo?.saveConfiguration(response!)
            } catch (let error) {
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
            let service = self.dependencyManager.resolve(type: MessageMixerServiceType.self)
            XCTAssertNotNil(service)

            let result = service?.ping()
            let response: PingResponse?
            do {
                response = try result?.get()
            } catch (let error) {
                XCTFail("Couldn't get a response from message mixer service. Error: \(error)")
                response = nil
            }
            XCTAssertNotNil(response)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.requestTimeout)
    }
}
