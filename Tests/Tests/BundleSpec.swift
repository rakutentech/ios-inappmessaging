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

            it("should return a valid inAppSdkVersion") {
                // swiftlint:disable:next line_length
                let semverRegex = #"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"#
                expect(bundleInfo.inAppSdkVersion).to(match(semverRegex))
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

            it("should return expected analyticsAccountNumber") {
                bundleMock.infoDictionaryMock[Constants.Info.analyticsAccountNumberKey] = 123
                expect(bundleInfo.analyticsAccountNumber).to(equal(123))
            }

            it("should return default analyticsAccountNumber if the key is not present in Info.plist") {
                expect(bundleInfo.analyticsAccountNumber).to(equal(1))
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
}

class BundleMock: Bundle {
    var infoDictionaryMock = [String: Any]()
    override var infoDictionary: [String: Any]? {
        infoDictionaryMock
    }

    init() {
        // super.init(path:) creates a new instance only if `path` is not bound to any existing Bundle instance
        super.init(path: Bundle.main.bundlePath + "/Frameworks")!
        infoDictionaryMock.removeAll()
    }
}
