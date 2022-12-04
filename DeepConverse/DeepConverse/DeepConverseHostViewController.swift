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
    private var webConfig:WKWebViewConfiguration {
        var callbacks = [String]()
        callbacks.append("closeTapped")
        callbacks.append("minimizeTapped")
        
        let newConfiguration = WKWebViewConfiguration()
        
        let wkPreferences = WKPreferences()
        wkPreferences.javaScriptEnabled = true
        newConfiguration.preferences = wkPreferences
        
        let userContentController = WKUserContentController()
        for callback in callbacks {
            userContentController.add(self, name: callback)
        }
        
        let closeButtonJS:String = closeButtonJS()
        let closeButtonUserScript:WKUserScript =  WKUserScript(
            source: closeButtonJS,
            injectionTime:WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: false
        )
        
        let minimizeButtonJS: String = minimizeButtonJS()
        let minimizeButtonUserScript: WKUserScript =  WKUserScript(
            source: minimizeButtonJS,
            injectionTime:WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: false
        )
        
        userContentController.addUserScript(closeButtonUserScript)
        userContentController.addUserScript(minimizeButtonUserScript)
        
        newConfiguration.userContentController = userContentController
        return newConfiguration
    }
    
    private func minimizeButtonJS() -> String {
        let script:String = "document.getElementById('your button id here').addEventListener('click', function () {window.webkit.messageHandlers.minimizeTapped.postMessage();});"
        return script;
    }
    
    private func closeButtonJS() ->String{
        let script:String = "document.getElementById('your button id here').addEventListener('click', function () {window.webkit.messageHandlers.closeTapped.postMessage();});"
        return script;
    }
    
    private var url: URL!
    private var timeout: Double!
    private var delegate: DeepConverseDelegate!
    
    static func createWebController(with url: URL,
                                    timeout: Double,
                                    delegate: DeepConverseDelegate) -> DeepConverseHostViewController {
        let bundle = Bundle(for: DeepConverseHostViewController.self)
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(DeepConverseHostViewController.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        configureWebview()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.delegate.didCloseBot()
        super.viewDidDisappear(animated)
    }
    
    private func configureWebview() {
        
        self.webview = WKWebView(frame: self.view.frame, configuration: webConfig)
        self.view.addSubview(self.webview)
        
        self.webview.scrollView.isScrollEnabled = false
        let webRequest = URLRequest(url: url,
                                    cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: timeout)
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
        let map = [String: String]()
        if (message.name == "closeTapped") {
            print("close tapped")
        } else if (message.name == "minimizeTapped") {
            print("minimize tapped")
        } else {
            print("other event")
        }
        delegate.didReceiveEvent(event: map)
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
