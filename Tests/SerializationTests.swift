import Quick
import Nimble
@testable import RInAppMessaging

class SerializationTests: QuickSpec {

    override func spec() {

        context("User Identifier") {
            it("should serialize with correct property names") {
                let identifier = UserIdentifier(type: .rakutenId, identifier: "TheUserID")
                let encoder = JSONEncoder()

                let encodedData = try? encoder.encode(identifier)
                expect(encodedData).toNot(beNil())
                let encodedString = String(data: encodedData!, encoding: .utf8)
                expect(encodedString).to(equal(#"{"id":"TheUserID","type":1}"#))
            }
        }
    }
}
