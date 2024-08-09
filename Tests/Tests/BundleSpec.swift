import Foundation
import Quick
import Nimble
@testable import RInAppMessaging

class BundleSpec: QuickSpec {

    override func spec() {
        describe("BundleInfo") {

            let bundleInfo = BundleInfoMocked.self
            var bundleMock: BundleMock!

            beforeEach {
                bundleMock = BundleMock()
                bundleInfo.bundleMock = bundleMock
            }

            it("should return expected applicationId") {
                bundleMock.infoDictionaryMock["CFBundleIdentifier"] = "bundle.id"
                expect(bundleInfo.applicationId).to(equal("bundle.id"))
            }

            it("should return expected appVersion") {
                bundleMock.infoDictionaryMock["CFBundleShortVersionString"] = "1.2.3"
                expect(bundleInfo.appVersion).to(equal("1.2.3"))
            }

            it("should return expected inAppSubscriptionId") {
                bundleMock.infoDictionaryMock[Constants.Info.subscriptionIDKey] = "sub-id"
                expect(bundleInfo.inAppSubscriptionId).to(equal("sub-id"))
            }

            it("should return expected inAppConfigurationURL") {
                bundleMock.infoDictionaryMock[Constants.Info.configurationURLKey] = "http://config.url"
                expect(bundleInfo.inAppConfigurationURL).to(equal("http://config.url"))
            }

            it("should return expected customFontNameTitle") {
                bundleMock.infoDictionaryMock[Constants.Info.customFontNameTitleKey] = "font-title"
                expect(bundleInfo.customFontNameTitle).to(equal("font-title"))
            }

            it("should return expected customFontNameText") {
                bundleMock.infoDictionaryMock[Constants.Info.customFontNameTextKey] = "font-text"
                expect(bundleInfo.customFontNameText).to(equal("font-text"))
            }

            it("should return expected customFontNameButton") {
                bundleMock.infoDictionaryMock[Constants.Info.customFontNameButtonKey] = "font-button"
                expect(bundleInfo.customFontNameButton).to(equal("font-button"))
            }

            it("should return rmcSdk version from plist") {
                bundleMock.resourceFiles = ["RmcInfo.plist": ["rmcSdkVersion": "1.0.1", "rmcRATAccountId": 999]]
                expect(bundleInfo.rmcSdkVersion).to(equal("1.0.1"))
            }
            it("should return rmcRATAccountId version from plist") {
                bundleMock.resourceFiles = ["RmcInfo.plist": ["rmcSdkVersion": "1.0.1", "rmcRATAccountId": 999]]
                expect(bundleInfo.rmcRATAccountId).to(equal(NSNumber(999)))
            }
        }

        describe("Bundle extensions") {
            it("should return non-nil value for sdkAssets property") {
                expect(Bundle.sdkAssets).toNot(beNil())
            }
        }
    }
}

class BundleInfoMocked: BundleInfo {
    static var bundleMock: BundleMock!
    override class var bundle: Bundle {
        bundleMock
    }
    override class var rmcBundle: Bundle? {
        bundleMock
    }
}

class BundleMock: Bundle {

    private let plistDirectory: String! = {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        return documentDirectory?.appending("/PlistMocks")
    }()
    var infoDictionaryMock = [String: Any]()
    var resourceFiles = [String: [String: Any]]() {
        didSet {
            recreateResourceFiles()
        }
    }
    override var infoDictionary: [String: Any]? {
        infoDictionaryMock
    }

    init(infoDictionary: [String: Any] = [:]) {
        infoDictionaryMock = infoDictionary
        // super.init(path:) creates a new instance only if `path` is not bound to any existing Bundle instance
        super.init(path: Bundle.main.bundlePath + "/Frameworks")!
    }

    override func path(forResource name: String?, ofType ext: String?) -> String? {
        guard let name = name else {
            return nil
        }
        var path = plistDirectory?.appending("/\(name)")
        if let ext {
            path?.append(".\(ext)")
        }
        return path
    }

    private func recreateResourceFiles() {
        let fileManager = FileManager.default
        let resourceURL: URL! = URL(string: "file://\(plistDirectory!)")

        try? fileManager.removeItem(at: resourceURL)
        try? fileManager.createDirectory(at: resourceURL, withIntermediateDirectories: true)

        resourceFiles.forEach { fileName, content in
            let url = resourceURL.appendingPathComponent(fileName)
            do {
                try NSDictionary(dictionary: content).write(to: url)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
