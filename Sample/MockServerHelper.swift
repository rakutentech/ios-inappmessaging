import Foundation
import Shock

// class is needed for `Bundle(for:)`
final class MockServerHelper {

    static var sampleAppMockServer: MockServer!

    static let standardRouting = MockHTTPRoute.collection(routes: [
        configRouteMock(jsonStub: "config"),
        displyPermissionRouteMock(jsonStub: "displayPermission"),
        impressionRouteMock()])

    static func setupForSampleApp() {
        sampleAppMockServer = MockServerHelper.setupNewServer(route: standardRouting)
        sampleAppMockServer.setup(route: MockServerHelper.pingRouteMock(jsonStub: "ping"))
        sampleAppMockServer.start()
    }

    static func setupNewServer(route: MockHTTPRoute) -> MockServer {
        let mockServer = MockServer(port: 6789, bundle: Bundle(for: self.self))
        mockServer.setup(route: .collection(routes: [route]))
        return mockServer
    }

    static func configRouteMock(jsonStub: String) -> MockHTTPRoute {
        .simple(
            method: .get,
            urlPath: "/config",
            code: 200,
            filename: jsonStub + ".json")
    }

    static func pingRouteMock(jsonStub: String) -> MockHTTPRoute {
        .simple(
            method: .post,
            urlPath: "/ping",
            code: 200,
            filename: jsonStub + ".json")
    }

    static func displyPermissionRouteMock(jsonStub: String) -> MockHTTPRoute {
        .simple(
            method: .post,
            urlPath: "/display_permission",
            code: 200,
            filename: jsonStub + ".json")
    }

    static func impressionRouteMock() -> MockHTTPRoute {
        .simple(
            method: .post,
            urlPath: "/impression",
            code: 200,
            filename: nil)
    }
}
