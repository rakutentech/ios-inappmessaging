import UIKit

@objc class CarouselView: UIView {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var carouselPageControl: UIPageControl!
    @IBOutlet private weak var carouselHeightConstraint: NSLayoutConstraint!

    private var images: [UIImage?] = []
    private var links: [String?] = []
    private var altTexts: [String?] = []
    private var heightPercentage: CGFloat = 1

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupOrientationObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func configure(images: [UIImage?], carouselData: Carousel?, maxHeightPercent: CGFloat = 1 ) {
        self.images = images
        getCarouselData(from: carouselData)
        heightPercentage = maxHeightPercent
        setupCollectionView()
        setupPageControl()
        collectionView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        carouselHeightConstraint.constant = collectionView.frame.width * getMaxImageAspectRatio() + 2
        collectionView.collectionViewLayout.invalidateLayout()
        layoutIfNeeded()
    }

    private func setupPageControl() {
        carouselPageControl.numberOfPages = images.count
        carouselPageControl.currentPage = 0
        carouselPageControl.currentPageIndicatorTintColor = .systemBlue
        carouselPageControl.pageIndicatorTintColor = .lightGray
        carouselPageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
        }
        collectionView.register(CarouselCell.self, forCellWithReuseIdentifier: "CarouselCell")
    }

    func setPageControlVisibility(isHdden: Bool) {
        carouselPageControl.isHidden = isHdden
    }

    @objc private func pageControlValueChanged() {
        let currentPage = carouselPageControl.currentPage
        collectionView.scrollToItem(at: IndexPath(item: currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension CarouselView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCell.identifier, for: indexPath) as? CarouselCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: images[indexPath.item],
                       altText: altTexts[indexPath.item] ?? "carousel_image_load_error".localized)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = collectionView.frame.width
        let itemHeight = itemWidth * getMaxImageAspectRatio()

        return  CGSize(width: itemWidth, height: itemHeight)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / collectionView.frame.width)
        carouselPageControl?.currentPage = page
    }

    func getMaxImageAspectRatio()-> CGFloat {
        guard let maxImage = images.compactMap({ $0 }).max(by: { $0.size.height < $1.size.height }) else {
            return .zero
        }
        return maxImage.size.height / maxImage.size.width
    }

    func getCarouselData(from carousel: Carousel?) {
        guard let images = carousel?.images, !images.isEmpty else {
            return
        }
        let sortedDetails = images.sorted { $0.key < $1.key }.prefix(Constants.CampaignMessage.carouselThreshold)
        
        self.links = sortedDetails.map { $0.value.link }
        self.altTexts = sortedDetails.map { $0.value.altText }
    }

    private func setupOrientationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleOrientationChange() {
        guard let collectionView = self.collectionView else { return }

        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        guard let visibleIndexPath = collectionView.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) else { return }

        collectionView.collectionViewLayout.invalidateLayout()
        DispatchQueue.main.async {
            collectionView.scrollToItem(at: visibleIndexPath, at: .centeredHorizontally, animated: false)
        }
    }
}
