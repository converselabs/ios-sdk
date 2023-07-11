//
//  DeepConverseHostViewController.swift
//  DeepConverse
//
//  Created by Ankit Angra on 2022-09-22.
//

import UIKit
import WebKit

class DeepConverseHostViewController: UIViewController {
    
    private var webview: WKWebView!
    private var url: URL!
    private var timeout: Double!
    private var delegate: DeepConverseDelegate!
    
    struct ChatbotActions: Codable {
        var action : String
    }
    
    static func createWebController(with url: URL,
                                    timeout: Double,
                                    delegate: DeepConverseDelegate) -> DeepConverseHostViewController {
        let bundle = Bundle(for: DeepConverseHostViewController.self)
        
        print("Webview URL:", url)
        
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
    
    private func actionButtonJs() -> String {
        let s = """
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
            print("message:", message.body);
            guard let payload = message.body as? [String: String] else { return }
            print("struct:", payload["action"])
            
            switch (payload["action"]) {
            case "open":
                print("open action");
                break;
            case "minimize":
                print("minimize action")
                self.dismiss(animated: true, completion: nil);
                break;
            default:
                print("unknown action")
            }
            
            delegate.didReceiveEvent(event: payload)
        } catch {
            print("DeepConverse event error")
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
