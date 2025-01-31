import UIKit

final class CarouselCell: UICollectionViewCell {
    static let identifier = "CarouselCell"

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 5
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(textLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = contentView.bounds
        
        let maxTextWidth = contentView.bounds.width * 0.8
        let textSize = textLabel.sizeThatFits(CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude))
        let textX = (contentView.bounds.width - textSize.width) / 2
        let textY = (contentView.bounds.height - textSize.height) / 2
        textLabel.frame = CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height)
    }

    func configure(with image: UIImage?, altText: String?, cellBgColor: UIColor) {
        let hasImage = (image != nil)
        backgroundColor = hasImage ? cellBgColor : .clear
        imageView.isHidden = !hasImage
        imageView.image = image
        textLabel.isHidden = hasImage
        textLabel.text = altText ?? "carousel_image_load_error".localized
        layoutIfNeeded()
        setNeedsLayout()
        imageView.layoutIfNeeded()
        imageView.setNeedsLayout()
    }
}

