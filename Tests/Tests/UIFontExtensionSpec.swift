import Quick
import Nimble
import class UIKit.UIFont
@testable import RInAppMessaging

class UIFontExtensionsSpec: QuickSpec {
    override func spec() {
        /// - Precondition: Host app `Info.plist` must have InAppMessagingCustomFontNameText and InAppMessagingCustomFontNameButton set with font PostScript names
        describe("UIFont+IAM") {
            context("when calling custom fonts") {
                let expectedFontName = "blank-Bold"

                var hasRegisteredFont: Bool {
                    (CTFontManagerCopyAvailablePostScriptNames() as? [String] ?? []).contains { $0 == expectedFontName }
                }

                /// - Warning: registers fonts globally
                /// - Precondition: `blank-Bold.otf` must be added to test app target
                /// - Precondition: `blank-Bold.otf` must have a PS name of "blank-Bold"
                func registerFont() {
                    guard let path = Bundle.main.url(forResource: "dummy-font", withExtension: "otf") else {
                        fatalError("font not in test app bundle")
                    }
                    if !CTFontManagerRegisterFontsForURL(path as CFURL, .none, nil) {
                        fatalError("Error loading Font!")
                    }
                    expect(hasRegisteredFont).to(beTrue())
                }

                it("will fallback to sys font") {
                    expect(hasRegisteredFont).to(beFalse())
                    let sysFont = UIFont.systemFont(ofSize: 16)
                    let btnFont = UIFont.iamButton(ofSize: 16)
                    expect(btnFont).to(equal(sysFont))
                    let textFont = UIFont.iamText(ofSize: 16)
                    expect(textFont).to(equal(sysFont))
                }

                it("will use custom fonts when setup") {
                    registerFont()
                    expect(BundleInfo.customFontNameText).to(equal(expectedFontName))
                    expect(BundleInfo.customFontNameButton).to(equal(expectedFontName))
                    let btnFont = UIFont.iamButton(ofSize: 16)
                    expect(btnFont.fontName).to(equal(expectedFontName))
                    let textFont = UIFont.iamText(ofSize: 16)
                    expect(textFont.fontName).to(equal(expectedFontName))
                }
            }
        }
    }
}
