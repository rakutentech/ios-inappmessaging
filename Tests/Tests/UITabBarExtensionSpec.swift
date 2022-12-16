import Quick
import Nimble
import UIKit
@testable import RInAppMessaging

class UITabBarExtensionsSpec: QuickSpec {

    override func spec() {

        describe("UITabBar+IAM") {

            context("when calling updateItemIdentifiers method") {

                var tabBar: UITabBar!
                var tabBarButtons: [UIView] {
                    tabBar.subviews.filter { $0.isKind(of: NSClassFromString("UIControl")!) }
                }

                beforeEach {
                    tabBar = UITabBar()
                }

                it("should set expected identifiers on UITabBarButton subviews") {
                    let item1 = UITabBarItem(title: "1", image: nil, selectedImage: nil)
                    let item2 = UITabBarItem(title: "2", image: nil, selectedImage: nil)
                    tabBar.setItems([item1, item2], animated: false)

                    expect(tabBarButtons).toNot(beEmpty())
                    expect(tabBarButtons.map({ $0.accessibilityIdentifier })).to(equal([nil, nil]))
                    item1.accessibilityIdentifier = "id1"
                    item2.accessibilityIdentifier = "id2"
                    tabBar.updateItemIdentifiers()

                    expect(tabBarButtons).to(containElementSatisfying({ $0.accessibilityIdentifier == "id2" }))
                    expect(tabBarButtons).to(containElementSatisfying({ $0.accessibilityIdentifier == "id1" }))
                }

                it("should not update identifiers if items and buttons don't match") {
                    let item1 = UITabBarItem(title: "1", image: nil, selectedImage: nil)
                    let item2 = UITabBarItem(title: "2", image: nil, selectedImage: nil)
                    tabBar.setItems([item1, item2], animated: false)

                    expect(tabBarButtons).toNot(beEmpty())
                    expect(tabBarButtons.map({ $0.accessibilityIdentifier })).to(equal([nil, nil]))
                    item1.accessibilityIdentifier = "id1"
                    item2.accessibilityIdentifier = "id2"
                    tabBarButtons.first?.removeFromSuperview()

                    expect(tabBarButtons).toNot(haveCount(2))
                    tabBar.updateItemIdentifiers()

                    expect(tabBarButtons).toNot(containElementSatisfying({ $0.accessibilityIdentifier == "id2" }))
                    expect(tabBarButtons).toNot(containElementSatisfying({ $0.accessibilityIdentifier == "id1" }))
                }
            }
        }
    }
}
