//
//  ViewController.swift
//  DeepConverse-Sample
//
//  Created by Ankit Angra on 2022-09-20.
//

import UIKit
import DeepConverse

class ViewController: UIViewController {

    private var sdk : DeepConverseSDK? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var metadata = [String:String]()
        metadata["hostname"] = "dcshow1-showbot.deepconverse.com "
        metadata["draft"] = "true"
        
        let session = DeepConverseSDKSession.init(
            subDomain: "cdn.converseapps.com/v1/assets/widget",
            botName: "embedded-chatbot",
            metadata: metadata,
            webViewTimeout: 60.0
        )
        sdk = DeepConverseSDK(delegate: self, session: session)
    }

    @IBAction func didOpen(_ sender: Any) {
        sdk?.openBot(viewController: self)
    }
    
    @IBOutlet weak var open: UIButton!
}

extension ViewController: DeepConverseDelegate {
    func didWebViewFail(withError: DeepConverseWebHostError) {
        print("Did fail with error")
    }
    
    func didReceiveEvent(event: [String : Any]) {
        
    }
    
    func didCloseBot() {
        print("Did Close")
    }
    
    func didOpenBot() {
        print("Did Open")
    }
}
