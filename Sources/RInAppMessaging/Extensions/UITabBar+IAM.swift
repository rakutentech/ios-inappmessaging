import UIKit

public extension UITabBar {

    /// Updates accessibilityIdentifer value of UITabBar buttons.
    /// The values are taken from corresponding UITabBarItem objects present in `items` array.
    @objc func updateItemIdentifiers() {
        guard let tabBarItems = items, !tabBarItems.isEmpty else {
            return
        }
        let tabBarButtons = subviews
            .filter { $0.isKind(of: NSClassFromString("UIControl")!) } // We are looking for instances of UITabBarButton private class
            .sorted { $0.frame.minX < $1.frame.minX } // Ensuring the right order

        guard tabBarButtons.count == items?.count else {
            IAMLogger.debug("Unexpected tab bar items setup: \(tabBarButtons) \(items ?? [])")
            return
        }

        zip(tabBarItems, tabBarButtons).forEach { (item, button) in
            button.accessibilityIdentifier = item.accessibilityIdentifier
        }
    }
}
