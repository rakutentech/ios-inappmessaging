import WebKit

/// Protocol for any IAM Views that are capable of supporting rich content.
internal protocol RichContentBrowsable {
    func createWebView(withHtmlString htmlString: String, andFrame frame: CGRect) -> WKWebView
}

extension RichContentBrowsable {
    func createWebView(withHtmlString htmlString: String, andFrame frame: CGRect) -> WKWebView {
        let webView = WKWebView()
        let headerString =
            "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'></header>"

        webView.loadHTMLString(headerString + htmlString, baseURL: nil)
        webView.frame = frame
        webView.contentMode = .scaleAspectFit

        return webView
    }
}
