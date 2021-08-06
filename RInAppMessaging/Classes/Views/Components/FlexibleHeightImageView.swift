import UIKit

/// `UIImageView` subclass that fixes problem with empty space
/// that appears when using `UIImageView` with scaleAspectFit mode
/// in container with dynamic height
internal class FlexibleHeightImageView: UIImageView {

    override var intrinsicContentSize: CGSize {
        guard let image = image, contentMode == .scaleAspectFill else {
            return super.intrinsicContentSize
        }

        let width = super.intrinsicContentSize.width
        let ratio = image.size.height / image.size.width

        return CGSize(width: width, height: bounds.width * ratio)
    }

    override func layoutSubviews() {
        invalidateIntrinsicContentSize()
        super.layoutSubviews()
    }
}
