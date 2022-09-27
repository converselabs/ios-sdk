//
//  DeepConverseHostViewController.swift
//  DeepConverse
//
//  Created by Ankit Angra on 2022-09-22.
//

import UIKit
import WebKit

class DeepConverseHostViewController: UIViewController {
    
    @IBOutlet weak var webview: WKWebView!
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
        configureWebview(callbacks: [""])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.delegate.didCloseBot()
        super.viewDidDisappear(animated)
    }
    
    private func configureWebview(callbacks: [String]) {
        let wkPreferences = WKPreferences()
        wkPreferences.javaScriptCanOpenWindowsAutomatically = true
        wkPreferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences = wkPreferences
        self.webview.scrollView.isScrollEnabled = false
        
        let webRequest = URLRequest(url: url,
                                    cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: timeout)
        self.webview.load(webRequest)
        
        for callback in callbacks {
            userContentController.add(self, name: callback)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if (self.webview.isLoading) {
                self.webview.stopLoading()
                self.delegate.didWebViewFail(withError: DeepConverseWebHostError.WebViewTimeout
                )
            }
        }
    }
}

extension DeepConverseHostViewController : WKScriptMessageHandler {
    public func userContentController (
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        
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
