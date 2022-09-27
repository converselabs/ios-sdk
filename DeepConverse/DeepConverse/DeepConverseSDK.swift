//
//  BotManager.swift
//  DeepConverse
//
//  Created by Ankit Angra on 2022-09-21.
//

import Foundation
import WebKit

public enum DeepConverseWebHostError: Error {
    case WebViewFailedToLoad
    case WebViewTimeout
}

public protocol DeepConverseDelegate {
    func didReceiveEvent(event: [String: Any])
    func didCloseBot()
    func didOpenBot()
    func didWebViewFail(withError: DeepConverseWebHostError)
}

public class DeepConverseSDKSession {
    
    var subDomain: String?
    var botName: String?
    var metadata: [String: String]?
    var openWebLinkInSafari: Bool
    var webViewTimeout: Double
    var navigationBarOpeque: Bool
    
    public init (
        subDomain: String,
        botName: String,
        metadata: [String: String],
        shouldOpenWebLinkInSafari: Bool = false,
        webViewTimeout: Double = 30.0,
        isNavigationBarOpeque: Bool = false
    ) {
        self.subDomain = subDomain
        self.botName = botName
        self.metadata = metadata
        self.openWebLinkInSafari = shouldOpenWebLinkInSafari
        self.webViewTimeout = webViewTimeout
        self.navigationBarOpeque = isNavigationBarOpeque
    }
}


public class DeepConverseSDK {
    
    private var delegate: DeepConverseDelegate
    
    private var webView: WKWebView?
    private var botUrl: URL?
    private var timeout: Double
    
    public init(delegate: DeepConverseDelegate, session: DeepConverseSDKSession) {
        self.delegate = delegate
        timeout = session.webViewTimeout
        createSession(session: session)
    }
    
    private func createSession (
        session: DeepConverseSDKSession
    ) {
        
        guard let subDomain = session.subDomain,
              let botName = session.botName,
              let context = session.metadata else {
            fatalError("Incorrect settings. Subdomain, Botname and Metadata should be initilized")
        }
        
        guard let url = createUrl (
            subdomain: subDomain,
            botName: botName,
            context: context
        ) else {
            fatalError("Unable to create the URL. Please check subdomain, botname and metadata in SDK settings")
        }
        
        botUrl = url
    }
    
    private func createUrl(
        subdomain: String,
        botName: String,
        context: [String: String]
    ) -> URL? {
        
        let urlString: String = "https://" + subdomain + "/" + botName
        
        guard let urlCompenent = NSURLComponents(string: urlString) else {
            return nil
        }
        
        var queryItems = [URLQueryItem]()
        
        for item in context {
            let queryItem = URLQueryItem.init(name: item.key, value: item.value)
            queryItems.append(queryItem)
        }
        
        urlCompenent.queryItems = queryItems
        
        return urlCompenent.url
    }
    
    public func openBot(viewController: UIViewController) {
        
        guard let url = botUrl else {
            fatalError("Something went wrong. Please check your session")
        }
        
        let vc = DeepConverseHostViewController.createWebController(with: url,
                                                                    timeout: timeout,
                                                                    delegate: delegate)
        viewController.present(vc, animated: true) {
            self.delegate.didOpenBot()
        }
    }
}





