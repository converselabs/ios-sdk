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
    case SDKInitilizationError
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
    var webViewTimeout: Double
    
    public init (
        subDomain: String,
        botName: String,
        metadata: [String: String],
        webViewTimeout: Double = 30.0
    ) {
        self.subDomain = subDomain
        self.botName = botName
        self.metadata = metadata
        self.webViewTimeout = webViewTimeout
    }
}


public class DeepConverseSDK {
    
    private static let BASE_URL = "https://cdn.converseapps.com/v1/assets/widget/embedded-chatbot"
    private var delegate: DeepConverseDelegate
    private var botUrl: URL?
    private var timeout: Double
    
    public init(delegate: DeepConverseDelegate, session: DeepConverseSDKSession) {
        self.delegate = delegate
        self.timeout = session.webViewTimeout
        createSession(session: session)
    }
    
    private func createSession (
        session: DeepConverseSDKSession
    ) {
        
        guard let subDomain = session.subDomain,
              let botName = session.botName,
              let context = session.metadata else {
            delegate.didWebViewFail(withError: DeepConverseWebHostError.SDKInitilizationError)
            return
        }
        
        guard let url = createUrl (
            subdomain: subDomain,
            botName: botName,
            context: context
        ) else {
            return
        }
        
        botUrl = url
    }
    
    private func createUrl(
        subdomain: String,
        botName: String,
        context: [String: String]
    ) -> URL? {
        
        guard let urlCompenent = NSURLComponents(string: DeepConverseSDK.BASE_URL) else {
            return nil
        }
        
        var queryItems = [URLQueryItem]()

        let config = subdomain + "-" + botName + ".deepconverse.com"
        let hostnameQI = URLQueryItem.init(name: "hostname", value: config)
        queryItems.append(hostnameQI)
        
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





