import WebKit

/// Class to initialize any webview created by InAppMessaging.
internal class InAppMessagingWebViewController: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var navigationBar: UINavigationBar!
    private var navItem: UINavigationItem!
    private var toolbar: UIToolbar!
    private var backButton: UIBarButtonItem!
    private var forwardButton: UIBarButtonItem!

    // Uri of the page to display.
    private var uri: String

    // Handles iPhone X un-safe areas.
    private var topSafeArea: CGFloat = 0
    private var bottomSafeArea: CGFloat = 0

    // Handles screen size responsiveness.
    private var currentHeight: CGFloat = 0
    private var toolBarOffset: CGFloat = 0

    private var observations = [NSKeyValueObservation]()

    init(uri: String) {
        self.uri = uri
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.backgroundColor = .white

        // To handle iPhone X un-safe areas.
        setUpSafeArea()

        // Navigation bar.
        setUpNavigationBar()

        // Progress view.
        setUpProgressView()

        // Tool bar.
        setUpToolBar()

        // Web view.
        setUpWebView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        observations.append(webView.observe(\.estimatedProgress, options: .new) { [unowned self] webView, _ in
            self.progressView.progress = Float(webView.estimatedProgress)
        })
        observations.append(webView.observe(\.title, options: .new) { [unowned self] webView, _ in
            self.navItem.title = webView.title
        })
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        forwardButton.isEnabled = webView.canGoForward
        backButton.isEnabled = webView.canGoBack
        progressView.isHidden = true
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

        // Update current URL of the site that is displaying.
        if let currentUrl = webView.url {
            uri = currentUrl.absoluteString
        }

        progressView.isHidden = false
    }

    // MARK: - Web view setup
    private func setUpSafeArea() {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow?.safeAreaInsets
            if let topPadding = window?.top,
                let bottomPadding = window?.bottom {
                topSafeArea = topPadding
                bottomSafeArea = bottomPadding
                currentHeight += topSafeArea
                toolBarOffset += bottomSafeArea
            }
        }

        currentHeight = (currentHeight == 0) ? 20 : currentHeight
        toolBarOffset = (toolBarOffset == 0) ? 44 : toolBarOffset + 44
    }

    private func setUpNavigationBar() {
        navigationBar = UINavigationBar(frame: CGRect(x: 0, y: currentHeight, width: UIScreen.main.bounds.width, height: 44))
        navigationBar.isTranslucent = false
        navItem = UINavigationItem(title: uri)

        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapOnWebViewDoneButton))
        navItem.rightBarButtonItem = doneItem
        navigationBar.setItems([navItem], animated: true)
        view.addSubview(navigationBar)

        currentHeight += navigationBar.frame.size.height
    }

    private func setUpProgressView() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame.size.width = UIScreen.main.bounds.width
        progressView.frame.origin.y = currentHeight - 2
        view.addSubview(progressView)
    }

    private func setUpToolBar() {
        toolbar = UIToolbar(frame: CGRect(x: 0,
                                          y: UIScreen.main.bounds.height - toolBarOffset,
                                          width: UIScreen.main.bounds.width,
                                          height: toolBarOffset))

        toolbar.isTranslucent = false

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        backButton = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(didTapOnBackButton))
        backButton.isEnabled = false

        forwardButton = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(didTapOnForwardButton))
        forwardButton.isEnabled = false

        let refreshButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(didTapOnRefreshButton))
        let actionButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didTapOnActionButton))

        toolbar.setItems([backButton, space, forwardButton, space, refreshButton, space, actionButton], animated: true)

        view.addSubview(toolbar)
    }

    private func setUpWebView() {
        webView = WKWebView(
            frame: CGRect(x: 0,
                          y: currentHeight,
                          width: UIScreen.main.bounds.width,
                          height: UIScreen.main.bounds.height - currentHeight - toolbar.frame.size.height),
            configuration: WKWebViewConfiguration())

        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self

        guard let url = URL(string: uri) else {
            CommonUtility.debugPrint("InAppMessaging: Invalid URI.")
            return
        }

        webView.load(URLRequest(url: url))
        view.addSubview(webView)
    }

    // MARK: - Button selectors for webviews.
    @objc private func didTapOnActionButton(sender: UIView) {
        let textToShare = uri
        let objectsToShare = [textToShare] as [Any]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.airDrop, .saveToCameraRoll, .print, .assignToContact]
        activityVC.popoverPresentationController?.sourceView = sender
        present(activityVC, animated: true, completion: nil)
    }

    @objc private func didTapOnWebViewDoneButton() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc private func didTapOnBackButton() {
        if webView.canGoBack && webView.url != nil {
            webView.goBack()
            webView.reload()
        }
    }

    @objc private func didTapOnForwardButton() {
        if webView.canGoForward && webView.url != nil {
            webView.goForward()
            webView.reload()
        }
    }

    @objc private func didTapOnRefreshButton() {
        if webView.url != nil {
            webView.reload()
        }
    }
}
