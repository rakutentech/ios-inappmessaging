import UIKit

@objc class CarouselView: UIView {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var carouselPageControl: UIPageControl!
    @IBOutlet weak var carouselHeightConstraint: NSLayoutConstraint!

    var carouselData: [CarouselData] = []
    private var timer: Timer?
    private var currentIndex = 0
    private var hasReachedLastImage = false
    private var campaignMode: Mode = .none
    private var carouselBgColor: UIColor = .clear
    var presenter: FullViewPresenterType?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        stopAutoScroll()
    }

    func configure(carouselData: [CarouselData], presenter: FullViewPresenterType, campaignMode: Mode, backgroundColor: UIColor) {
        self.carouselData = carouselData
        self.presenter = presenter
        self.campaignMode = campaignMode
        self.carouselBgColor = backgroundColor
        setupCollectionView()
        setupPageControl()
        startAutoScroll()
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

        collectionView.backgroundColor = (carouselData[indexPath.item].image != nil) ? carouselBgColor : .clear
        cell.configure(with: carouselData[indexPath.item].image,
                       altText: carouselData[indexPath.item].altText,
                       cellBgColor: carouselBgColor)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if campaignMode == .fullScreen {
            return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
        }
        let itemWidth = collectionView.frame.width
        let itemHeight = itemWidth * getMaxImageAspectRatio()
        return  CGSize(width: itemWidth, height: adjustHeight(height: itemHeight))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = carouselData[indexPath.item]

        guard let redirectLink = item.link,
              item.image != nil else { return }
        presenter?.didClickCampaignImage(url: redirectLink)
    }
}

extension CarouselView {

    func getMaxImageAspectRatio() -> CGFloat {
        guard let maxImageData = carouselData.compactMap({ $0.image }).max(by: { $0.size.height < $1.size.height })
            else { return .zero }
        return maxImageData.size.height / maxImageData.size.width
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleOrientationChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appdidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc private func appDidEnterBackground(){
        stopAutoScroll()
    }

    @objc private func appdidBecomeActive() {
        startAutoScroll()
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / collectionView.frame.width)
        carouselPageControl?.currentPage = page

        guard !hasReachedLastImage else { return }
        let maxOffsetX = collectionView.contentSize.width - collectionView.frame.width
        hasReachedLastImage = scrollView.contentOffset.x >= maxOffsetX
    }

    func startAutoScroll() {
        stopAutoScroll()
        guard !hasReachedLastImage else { return }
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(scrollToNextItem), userInfo: nil, repeats: true)
    }

    func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func scrollToNextItem() {
        guard !carouselData.isEmpty else { return }

        if currentIndex == carouselData.count - 1 {
            stopAutoScroll() // Stop at the last image
            hasReachedLastImage = true
            return
        }

        let nextIndex = currentIndex + 1
        let indexPath = IndexPath(item: nextIndex, section: 0)

        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        currentIndex = nextIndex
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndexPath = collectionView.indexPathsForVisibleItems.first
        currentIndex = visibleIndexPath?.item ?? 0

        // Only restart auto-scroll if the user interacted before reaching the last image for the first time
        if currentIndex < carouselData.count - 1 && !hasReachedLastImage {
            startAutoScroll()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let visibleIndexPath = collectionView.indexPathsForVisibleItems.first
        currentIndex = visibleIndexPath?.item ?? 0
    }
}

struct CarouselData {
    var image: UIImage?
    var altText: String?
    var link: String?
}
