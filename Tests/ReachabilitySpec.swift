import Quick
import Nimble
@testable import RInAppMessaging

class ReachabilitySpec: QuickSpec {

    override func spec() {

        describe("Reachability") {

            context("when initializing") {

                it("can't be set up with empty host name") {
                    expect(Reachability(hostname: "")).to(beNil())
                }

                it("can be set up with random host name") {
                    expect(Reachability(hostname: "a host")).toNot(beNil())
                }

                it("can be set up using standard http/https scheme format") {
                    let url = URL(string: "https://google.com/")!
                    expect(Reachability(url: url)).toNot(beNil())
                }

                it("can be set up using standard http/https scheme format with parameters") {
                    let url = URL(string: "https://host.com/data/RapidBoard.jspa?rapidView=15&projectKey=IAM")!
                    expect(Reachability(url: url)).toNot(beNil())
                }

                it("can't be set up with an URL that doesn't contain host name") {
                    let url = URL(string: "host")!
                    expect(Reachability(url: url)).to(beNil())
                }

                it("can be set up with an URL that uses ftp scheme") {
                    let url = URL(string: "ftp://host.com")!
                    expect(Reachability(url: url)).toNot(beNil())
                }
            }
        }
    }
}
