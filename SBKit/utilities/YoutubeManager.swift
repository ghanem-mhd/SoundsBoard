//
//  YoutubeVideoExtractor.swift
//  YoutubeVideoUrlExtract
//
//  Created by Mohammed Ghannm on 03.05.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import SDDownloadManager


public protocol YoutubeManagerDelegate: class {
    func URLNotSupported()
    func downloadDidStart()
    func downloadDidFailed()
    func downloadOnProgress(_ progress : CGFloat)
    func downloadDidFinished(_ error : Error?, _ fileUrl:URL?)
}

public class YoutubeManager{
    
    public static func downloadVideo(youtubeURL:String, delegate: YoutubeManagerDelegate){
        let videoIDOptional = URLComponents(string: youtubeURL)?.queryItems?.first(where: { $0.name == "v" })?.value
        guard let videoID = videoIDOptional else{
            delegate.URLNotSupported()
            return
        }
        delegate.downloadDidStart()
        extractVideos(delegate: delegate,from: videoID) { (url) -> (Void) in
            guard let mp4VideoURL = url else{
                print("Could not find the mp4 streaming URL!")
                delegate.downloadDidFailed()
                return
            }
            guard let requestURL = URL(string: mp4VideoURL) else{
                print("Could not create mp4 streaming request URL!")
                delegate.downloadDidFailed()
                return
            }
            let downloadedFileName = "\(videoID).mp4"
            _ = SDDownloadManager.shared.downloadFile(withRequest: URLRequest(url: requestURL),
                                                  inDirectory: "downloads",
                                                  withName: downloadedFileName,
                                                  shouldDownloadInBackground: false,
                                                  onProgress:
                { (progress) in
                    delegate.downloadOnProgress(progress)
            }) { (error, url) in
                  delegate.downloadDidFinished(error, url)
            }
        }
    }
    
    private static func extractVideos(delegate: YoutubeManagerDelegate,from youtubeId : String, completion: @escaping ((String?) -> (Void))){
        let strUrl = "http://www.youtube.com/get_video_info?video_id=\(youtubeId)&el=embedded&ps=default&eurl=&gl=US&hl=en"
        let url = URL(string: strUrl)!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                delegate.downloadDidFailed()
                return
            }
            guard (response as? HTTPURLResponse) != nil else {
                print(response as Any)
                delegate.downloadDidFailed()
                return
            }
            guard let d = data else{
                delegate.downloadDidFailed()
                return
            }
            if let string = String(data: d, encoding: .utf8) {
                let url = getDictionaryFrom(string: string)
                completion(url)
            }
        }.resume()
        
    }
    
    private static func getDictionaryFrom(string: String) -> String? {
        let parts = string.components(separatedBy: "&")
        for part in parts{
            let keyVal = part.components(separatedBy: "=")
            if (keyVal.count > 1 && keyVal[0] == "player_response"){
                guard let jsonString = keyVal[1].removingPercentEncoding else{
                    return nil
                }
                guard let dic = convertToDictionary(text: jsonString) else{
                    return nil
                }
                if let streamingData = dic["streamingData"] as? [String: Any]{
                    if let formats = streamingData["formats"] as? [Any]{
                        if (formats.count >= 1){
                            if let format = formats[0] as? [String: Any]{
                                if let url = format["url"] as? String{
                                    return url
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
}
