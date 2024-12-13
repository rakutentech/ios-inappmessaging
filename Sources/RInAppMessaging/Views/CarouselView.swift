import UIKit

@objc class CarouselView: UIView {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var carouselPageControl: UIPageControl!
    @IBOutlet weak var carouselHeightConstraint: NSLayoutConstraint!

    var carouselData: [CarouselData] = []

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupOrientationObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func configure(carouselData: [CarouselData]) {
        self.carouselData = carouselData
        setupCollectionView()
        setupPageControl()
        collectionView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let carouselHeight = collectionView.frame.width * getMaxImageAspectRatio() + 2
        
        carouselHeightConstraint.constant = adjustHeight(height: carouselHeight)
        collectionView.collectionViewLayout.invalidateLayout()
        layoutIfNeeded()
    }

    private func setupPageControl() {
        carouselPageControl.numberOfPages = carouselData.count
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
}

extension CarouselView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return carouselData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCell.identifier, for: indexPath) as? CarouselCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: carouselData[indexPath.item].image,
                       altText: carouselData[indexPath.item].altText)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = collectionView.frame.width
        let itemHeight = itemWidth * getMaxImageAspectRatio()
        return  CGSize(width: itemWidth, height: adjustHeight(height: itemHeight))
    }
}

extension CarouselView {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / collectionView.frame.width)
        carouselPageControl?.currentPage = page
    }

    func getMaxImageAspectRatio() -> CGFloat {
        guard let maxImageData = carouselData.compactMap({ $0.image }).max(by: { $0.size.height < $1.size.height })
            else { return .zero }
        return maxImageData.size.height / maxImageData.size.width
    }

    private func setupOrientationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc func handleOrientationChange() {
        guard let collectionView = self.collectionView else { return }

        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        guard let visibleIndexPath = collectionView.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) else { return }

        collectionView.collectionViewLayout.invalidateLayout()
        DispatchQueue.main.async {
            collectionView.scrollToItem(at: visibleIndexPath, at: .centeredHorizontally, animated: false)
        }
    }

    @objc func pageControlValueChanged() {
        let currentPage = carouselPageControl.currentPage
        collectionView.scrollToItem(at: IndexPath(item: currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    func adjustHeight(height: CGFloat) -> CGFloat {
        return height < Constants.Carousel.minHeight ? Constants.Carousel.defaultHeight : height
    }
}
