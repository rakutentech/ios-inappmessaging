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

            describe("Carousel model") {
                var carousel: Carousel?
                var jsonData: Data!

                context("when JSON contains all fields") {
                    beforeEach {
                        jsonData = Data("""
                                {
                                    "carousel": {
                                        "images": {
                                            "0": {
                                                "img_url": "URL link",
                                                "link": "https://redirecturl",
                                                "alt_text": "unable to load image"
                                            },
                                            "1": {
                                                "img_url": "URL link",
                                                "link": "https://redirecturl",
                                                "alt_text": "unable to load image"
                                            }
                                        }
                                    }
                                }
                                """.utf8)
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let decodedData = try? decoder.decode([String: Carousel].self, from: jsonData)
                        carousel = decodedData?["carousel"]
                    }

                    it("decodes the images dictionary") {
                        expect(carousel?.images).toNot(beNil())
                        expect(carousel?.images?.count).to(equal(2))
                    }

                    it("decodes image details correctly") {
                        let firstImage = carousel?.images?["0"]
                        expect(firstImage?.imgUrl).to(equal("URL link"))
                        expect(firstImage?.link).to(equal("https://redirecturl"))
                        expect(firstImage?.altText).to(equal("unable to load image"))
                    }
                }

                context("when JSON is missing some fields") {
                    beforeEach {
                        jsonData = Data("""
                                {
                                    "carousel": {
                                        "images": {
                                            "0": {
                                                "img_url": "URL link"
                                            }
                                        }
                                    }
                                }
                                """.utf8)
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let decodedData = try? decoder.decode([String: Carousel].self, from: jsonData)
                        carousel = decodedData?["carousel"]
                    }

                    it("decodes with nil for missing fields") {
                        let firstImage = carousel?.images?["0"]
                        expect(firstImage?.imgUrl).to(equal("URL link"))
                        expect(firstImage?.link).to(beNil())
                        expect(firstImage?.altText).to(beNil())
                    }
                }

                context("when JSON has no images") {
                    beforeEach {
                        jsonData = Data("""
                                {
                                    "carousel": {}
                                }
                                """.utf8)
                        let decodedData = try? JSONDecoder().decode([String: Carousel].self, from: jsonData)
                        carousel = decodedData?["carousel"]
                    }

                    it("decodes images as nil") {
                        expect(carousel?.images).to(beNil())
                    }
                }

                context("when JSON is completely empty") {
                    beforeEach {
                        jsonData = Data("{}".utf8)
                        let decodedData = try? JSONDecoder().decode([String: Carousel].self, from: jsonData)
                        carousel = decodedData?["carousel"]
                    }

                    it("decodes carousel as nil") {
                        expect(carousel).to(beNil())
                    }
                }

                context("when JSON contains 'carousel' key but no images") {
                    beforeEach {
                        jsonData = Data("""
                        {
                            "carousel": {}
                        }
                        """.utf8)

                        let decodedData = try? JSONDecoder().decode([String: Carousel].self, from: jsonData)
                        carousel = decodedData?["carousel"]
                    }

                    it("decodes images as nil") {
                        expect(carousel?.images).to(beNil())
                    }
                }

                context("when 'images' is an empty dictionary") {
                    beforeEach {
                        jsonData = Data("""
                        {
                            "carousel": {
                                "images": {}
                            }
                        }
                        """.utf8)

                        let decodedData = try? JSONDecoder().decode([String: Carousel].self, from: jsonData)
                        carousel = decodedData?["carousel"]
                    }

                    it("decodes images as an empty dictionary") {
                        expect(carousel?.images).toNot(beNil())
                        expect(carousel?.images?.isEmpty).to(beTrue())
                    }
                }

                context("when images contain empty ImageDetails objects") {
                    beforeEach {
                        jsonData = Data("""
                        {
                            "carousel": {
                                "images": {
                                    "0": {}
                                }
                            }
                        }
                        """.utf8)

                        let decodedData = try? JSONDecoder().decode([String: Carousel].self, from: jsonData)
                        carousel = decodedData?["carousel"]
                    }

                    it("decodes ImageDetails with all fields as nil") {
                        let firstImage = carousel?.images?["0"]
                        expect(firstImage?.imgUrl).to(beNil())
                        expect(firstImage?.link).to(beNil())
                        expect(firstImage?.altText).to(beNil())
                    }
                }
            }
        }
    }
}
