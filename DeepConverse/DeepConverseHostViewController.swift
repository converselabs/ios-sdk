//
//  DeepConverseHostViewController.swift
//  DeepConverse
//
//

import UIKit
import WebKit

class DeepConverseHostViewController: UIViewController {

    private var webview: WKWebView!
    private var url: URL!
    private var timeout: Double!
    private var delegate: DeepConverseDelegate!
    private var session: DeepConverseSDKSession!

    struct ChatbotActions: Codable {
        var action : String
    }

    static func createWebController(with url: URL,
                                    session: DeepConverseSDKSession,
                                    timeout: Double,
                                    delegate: DeepConverseDelegate) -> DeepConverseHostViewController {
        let bundle = Bundle(for: DeepConverseHostViewController.self)

        print("[DeepConverseSDK] Webview URL:", url)
        print("[DeepConverseSDK] Metadata: ", session.metadata)

        var storyboard:UIStoryboard

        if (bundle.path(forResource: "DeepConverse", ofType: "bundle") != nil){
            let frameworkBundlePath = bundle.path(forResource: "DeepConverse", ofType: "bundle")!
            let frameworkBundle = Bundle(path: frameworkBundlePath)
            storyboard = UIStoryboard(name: "DeepConverseHostViewController", bundle: frameworkBundle)
        } else {
            storyboard = UIStoryboard(name: "DeepConverseHostViewController", bundle: bundle)
        }

        guard let viewController = storyboard.instantiateInitialViewController() as? DeepConverseHostViewController else { fatalError("This should never, ever happen.") }
        viewController.url = url
        viewController.timeout = timeout
        viewController.delegate = delegate
        viewController.session = session
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(DeepConverseHostViewController.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        configureWebview()
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.delegate.didCloseBot()
        super.viewDidDisappear(animated)
    }

    private func json(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }

    private func actionButtonJs() -> String {
        do {
            var metadataJSON = json(from: self.session.metadata)
            print("[DeepConverseSDK] Metadata:", metadataJSON)
            let s = """
        setTimeout(function () {var evt = new CustomEvent('botWidgetInit', { detail: \(metadataJSON!) });document.dispatchEvent(evt);}, 100)

        document.addEventListener('dc.bot', function(e) {
          let payload = { action: e.detail.action };
          window.webkit.messageHandlers.actionTapped.postMessage(payload);
        });
        """
            return s;
        } catch {
            print("[DeepConverseSDK] Error in Metadata" + error.localizedDescription);
        }

        let s = """
        setTimeout(function () {var evt = new CustomEvent('botWidgetInit', { detail: {} });document.dispatchEvent(evt);}, 100)

        document.addEventListener('dc.bot', function(e) {
          let payload = { action: e.detail.action };
          window.webkit.messageHandlers.actionTapped.postMessage(payload);
        });
        """
        return s;
    }

    private func configureWebview() {

        let webConfiguration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let js: String = actionButtonJs();
        let userScript = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        contentController.removeAllUserScripts()
        contentController.addUserScript(userScript)
        contentController.add(
                    self,
                    name: "actionTapped"
                )
        webConfiguration.userContentController = contentController

        self.webview = WKWebView(frame: self.view.frame, configuration: webConfiguration)
        self.webview.navigationDelegate = self
        self.view.addSubview(self.webview)

        self.webview.scrollView.isScrollEnabled = false
        let webRequest = URLRequest(url: url,
                                    cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: timeout)

        let layoutGuide = self.view.safeAreaLayoutGuide
        self.webview.translatesAutoresizingMaskIntoConstraints = false
        self.webview.leadingAnchor.constraint(
              equalTo: layoutGuide.leadingAnchor).isActive = true
        self.webview.trailingAnchor.constraint(
              equalTo: layoutGuide.trailingAnchor).isActive = true
        self.webview.topAnchor.constraint(
              equalTo: layoutGuide.topAnchor).isActive = true
        self.webview.bottomAnchor.constraint(
              equalTo: layoutGuide.bottomAnchor).isActive = true

        self.webview.load(webRequest)

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if (self.webview.isLoading) {
                self.webview.stopLoading()
                self.delegate.didWebViewFail(withError: DeepConverseWebHostError.WebViewTimeout)
            }
        }
    }
}

extension DeepConverseHostViewController : WKScriptMessageHandler {
    public func userContentController (
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        do {
            print("[DeepConverseSDK] message:", message.body);
            guard let payload = message.body as? [String: String] else { return }
            print("struct:", payload["action"])

            switch (payload["action"]) {
            case "open":
                print("[DeepConverseSDK] open action");
                break;
            case "minimize":
                print("[DeepConverseSDK] minimize action")
                self.dismiss(animated: true, completion: nil);
                break;
            default:
                print("[DeepConverseSDK] unknown action")
            }

            delegate.didReceiveEvent(event: payload)
        } catch {
            print("[DeepConverseSDK] Event error")
        }
    }
}



extension DeepConverseHostViewController {
    @objc func keyboardWillHide(notification: NSNotification) {
        if #available(iOS 12.0, *) {
            guard let webView = webview else { return }
            for view in webView.subviews {
                if view.isKind(of: NSClassFromString("WKScrollView") ?? UIScrollView.self) {
                    guard let scroller = view as? UIScrollView else { return }
                    scroller.contentOffset = CGPoint(x: 0, y: 0)
                }
            }
        }
    }
}

extension DeepConverseHostViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print(navigationAction)
        guard case .linkActivated = navigationAction.navigationType,
              let url = navigationAction.request.url
        else {
            decisionHandler(.allow)
            return
        }
        
        print("[DeepConverseSDK] Link clicked: ", url)
        
        decisionHandler(.cancel)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
   }
}
