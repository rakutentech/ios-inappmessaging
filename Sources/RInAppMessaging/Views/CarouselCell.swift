import UIKit

class CarouselCell: UICollectionViewCell {
    static let identifier = "CarouselCell"
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let textLabel: UILabel = {
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

    func configure(with image: UIImage?, altText: String) {
        if let image = image {
            imageView.image = image
            textLabel.isHidden = true
        } else {
            imageView.image = UIImage()
            textLabel.isHidden = false
        }
        textLabel.text = altText
        setNeedsLayout()
    }
}

