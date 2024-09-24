import Quick
import Nimble
@testable import RInAppMessaging

class CustomJsonSpec: QuickSpec {
    override func spec() {
        describe("CustomJson") {
            context("when initialized with all properties") {
                let primerButton = PrimerButton(button: 1)
                let clickableImage = ClickableImage(url: "http://example.com/image.png")
                let backgroundColor = BackgroundColor(opacity: 0.5)

                let customJson = CustomJson(pushPrimer: primerButton, clickableImage: clickableImage, background: backgroundColor)

                it("should have the correct properties") {
                    expect(customJson.pushPrimer).to(equal(primerButton))
                    expect(customJson.clickableImage).to(equal(clickableImage))
                    expect(customJson.background).to(equal(backgroundColor))
                }
            }

            context("when initialized with nil properties") {
                let customJson = CustomJson()

                it("should have nil properties") {
                    expect(customJson.pushPrimer).to(beNil())
                    expect(customJson.clickableImage).to(beNil())
                    expect(customJson.background).to(beNil())
                }
            }

            context("when decoding from valid JSON") {
                it("should decode correctly") {
                    let jsonString = """
                    {
                        "pushPrimer": {"button": 1},
                        "clickableImage": {"url": "http://example.com/image.png"},
                        "background": {"opacity": 0.5}
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let decodedJson = try? decoder.decode(CustomJson.self, from: jsonData)

                    expect(decodedJson).toNot(beNil())
                    expect(decodedJson?.pushPrimer?.button).to(equal(1))
                    expect(decodedJson?.clickableImage?.url).to(equal("http://example.com/image.png"))
                    expect(decodedJson?.background?.opacity).to(equal(0.5))
                }
            }

            context("when decoding from invalid JSON") {
                it("should return nil for missing required fields") {
                    let jsonString = """
                    {
                        "pushPrimer": {"button": 1},
                        "clickableImage": {}
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let decodedJson = try? decoder.decode(CustomJson.self, from: jsonData)

                    expect(decodedJson).toNot(beNil())
                    expect(decodedJson?.pushPrimer?.button).to(equal(1))
                    expect(decodedJson?.clickableImage?.url).to(beNil())
                    expect(decodedJson?.background).to(beNil())
                }

                it("should fail decoding due to incorrect data types") {
                    let jsonString = """
                    {
                        "pushPrimer": {"button": "notAnInteger"},
                        "clickableImage": {"url": 12345},
                        "background": {"opacity": "notADouble"}
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let decodedJson = try? decoder.decode(CustomJson.self, from: jsonData)

                    expect(decodedJson).toNot(beNil())
                    expect(decodedJson?.pushPrimer?.button).to(beNil())
                    expect(decodedJson?.clickableImage?.url).to(beNil())
                    expect(decodedJson?.background?.opacity).to(beNil())
                }

                it("should fail decoding when fields are strings instead of objects") {
                    let jsonString = """
                    {
                        "pushPrimer": "string",
                        "clickableImage": "string",
                        "background": "string"
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!

                    let decoder = JSONDecoder()
                    let decodedJson = try? decoder.decode(CustomJson.self, from: jsonData)

                    expect(decodedJson).toNot(beNil())
                    expect(decodedJson?.pushPrimer).to(beNil())
                    expect(decodedJson?.clickableImage).to(beNil())
                    expect(decodedJson?.background).to(beNil())
                }
            }
        }

        describe("PrimerButton") {
            context("when decoding from valid JSON") {
                it("should decode correctly") {
                    let jsonString = """
                    {
                        "button": 1
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!

                    let decoder = JSONDecoder()
                    let decodedButton = try? decoder.decode(PrimerButton.self, from: jsonData)

                    expect(decodedButton).toNot(beNil())
                    expect(decodedButton?.button).to(equal(1))
                }
            }

            context("when decoding from invalid JSON") {
                it("should return nil for invalid data type") {
                    let jsonString = """
                    {
                        "button": "notAnInteger"
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!

                    let decoder = JSONDecoder()
                    let decodedButton = try? decoder.decode(PrimerButton.self, from: jsonData)

                    expect(decodedButton?.button).to(beNil())
                }
            }
        }

        describe("ClickableImage") {
            context("when decoding from valid JSON") {
                it("should decode correctly") {
                    let jsonString = """
                    {
                        "url": "http://example.com/image.png"
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let decodedImage = try? decoder.decode(ClickableImage.self, from: jsonData)
                    expect(decodedImage).toNot(beNil())
                    expect(decodedImage?.url).to(equal("http://example.com/image.png"))
                }
            }

            context("when decoding from invalid JSON") {
                it("should return nil for invalid data type") {
                    let jsonString = """
                    {
                        "url": 12345
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!

                    let decoder = JSONDecoder()
                    let decodedImage = try? decoder.decode(ClickableImage.self, from: jsonData)

                    expect(decodedImage?.url).to(beNil())
                }
            }
        }

        describe("BackgroundColor") {
            context("when decoding from valid JSON") {
                it("should decode correctly") {
                    let jsonString = """
                    {
                        "opacity": 0.5
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let decodedBackground = try? decoder.decode(BackgroundColor.self, from: jsonData)

                    expect(decodedBackground).toNot(beNil())
                    expect(decodedBackground?.opacity).to(equal(0.5))
                }
            }

            context("when decoding from invalid JSON") {
                it("should return nil for invalid data type") {
                    let jsonString = """
                    {
                        "opacity": "notADouble"
                    }
                    """
                    let jsonData = jsonString.data(using: .utf8)!

                    let decoder = JSONDecoder()
                    let decodedBackground = try? decoder.decode(BackgroundColor.self, from: jsonData)

                    expect(decodedBackground?.opacity).to(beNil())
                }
            }
        }
    }
}
