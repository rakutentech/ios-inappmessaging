import Quick
import Nimble
import UIKit.UILabel
@testable import RInAppMessaging

class UILabelExtensionSpec: QuickSpec {
    override func spec() {
        describe("UILabel+IAM") {
            context("when calling setLineSpacing") {
                func getParaghraphStyle(for label: UILabel) -> NSMutableParagraphStyle? {
                    guard let text = label.text, !text.isEmpty, let style = label
                        .attributedText?
                        .attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil)
                        as? NSMutableParagraphStyle else {
                        return nil
                    }
                    return style
                }

                it("will not set the line spacing when the text is nil") {
                    let label = UILabel()
                    label.setLineSpacing(lineSpacing: 4.0)

                    expect(getParaghraphStyle(for: label)).to(beNil())
                }

                it("will set the line spacing as expected value") {
                    let label = UILabel()
                    label.text = "test label \n test label line 2"
                    label.setLineSpacing(lineSpacing: 4.0)

                    expect(getParaghraphStyle(for: label)?.lineSpacing).to(equal(4.0))
                }

                it("will replace line spacing as expected value") {
                    let label = UILabel()
                    label.text = "test label \n lest label line 2"

                    guard let attributedText = label.attributedText else {
                        return
                    }

                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 4.2
                    paragraphStyle.alignment = .center

                    let attributedString = NSMutableAttributedString(attributedString: attributedText)
                    attributedString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                                  value: paragraphStyle,
                                                  range: NSRange(location: 0, length: attributedString.length))
                    label.attributedText = attributedString

                    label.setLineSpacing(lineSpacing: 4.75)

                    let style = getParaghraphStyle(for: label)
                    expect(style?.lineSpacing).to(equal(4.75))
                }
            }
        }
    }
}
