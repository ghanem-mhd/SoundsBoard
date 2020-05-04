//
//  ShareExtensionHandler.swift
//  SBKit
//
//  Created by Mohammed Ghannm on 04.05.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import MobileCoreServices


public protocol ShareExtensionHandlerDelegate: class {
    func handleDidStart()
    func handleDidFailed()
    func handleDidFinished(audioVideoURL:URL)
    func handleDidFinished(youtubeURL:String)
}

class ShareExtensionHandler{
    
    
    public static func handle(extensionContext: NSExtensionContext?, delegate: ShareExtensionHandlerDelegate){
        delegate.handleDidStart()
        guard let context = extensionContext else{
            delegate.handleDidFailed()
            return
        }
        guard let sharedItem = context.inputItems as? [NSExtensionItem] else{
            delegate.handleDidFailed()
            return
        }
        guard let itemProviders = sharedItem[0].attachments else{
            delegate.handleDidFailed()
            return
        }
        guard itemProviders.count >= 1 else{
            delegate.handleDidFailed()
            return
        }
        var videoOrAudioContent = false
        var videoURL = false
        if (itemProviders[0].hasItemConformingToTypeIdentifier(String(kUTTypeAudiovisualContent))) {
            videoOrAudioContent = true
            itemProviders[0].loadItem(forTypeIdentifier: String(kUTTypeAudiovisualContent), options: nil, completionHandler: { (sharedData, error) in
                DispatchQueue.main.async {
                    if let url = sharedData as? URL{
                        delegate.handleDidFinished(audioVideoURL: url)
                    }else{
                        delegate.handleDidFailed()
                    }
                }
            })
        }
        if (itemProviders[0].hasItemConformingToTypeIdentifier(String(kUTTypePlainText))) {
            videoURL = true
            itemProviders[0].loadItem(forTypeIdentifier: String(kUTTypePlainText), options: nil, completionHandler: { (sharedData, error) in
                DispatchQueue.main.async {
                    if let e = error{
                        print(e)
                        delegate.handleDidFailed()
                    }
                    if let urlString = sharedData as? String{
                        delegate.handleDidFinished(youtubeURL: urlString)
                    }else{
                        delegate.handleDidFailed()
                    }
                }
            })
        }
        if !videoURL && !videoOrAudioContent{
            delegate.handleDidFailed()
        }
    }
}
