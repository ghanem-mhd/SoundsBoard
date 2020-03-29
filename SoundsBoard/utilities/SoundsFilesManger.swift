//
//  SoundsFilesManger.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 11.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import MobileCoreServices
import AudioKit
import AVFoundation


enum SupportedFileTypes {
    case audio
    case video
    case unknowen
}

protocol SoundsFilesMangerCopyDelegate: class {
    func copyDidStart()
    func copyDidFinish(_ soundFileName: String)
    func copyDidFaild(_ erorr: Error)
}

class SoundsFilesManger{
    
    static func deleteSoundFile(_ soundFileName:String){
        deleteFile(getSoundURL(soundFileName))
    }
    
    static func deleteFile(_ url:URL){
        do {
            print("Deleting file at \(url)")
            try FileManager.default.removeItem(at: url)
        } catch let error as NSError {
            print("Error Domain: \(error.domain)")
            print("Error: \(error)")
        }
    }
    
    static func getFilesFromDocumentsFolder() -> [String]?
    {
        let fileMngr = FileManager.default;
        let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        return try? fileMngr.contentsOfDirectory(atPath:docs)
    }
    
    static func getSoundURL(_ soundFileName:String) -> URL {
        return getDocumentsDirectory().appendingPathComponent(soundFileName)
    }
    
    static func getTemporalURL() -> URL {
        let fileName = generateSoundFileName()
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }
    
    static func generateSoundFileName() -> String {
        return "\(NSUUID().uuidString).m4a"
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func checkFileType(_ url:URL) -> SupportedFileTypes{
        let urlExtension = NSURL(fileURLWithPath: url.path).pathExtension
        guard let uti = UTTypeCreatePreferredIdentifierForTag( kUTTagClassFilenameExtension,urlExtension! as CFString,nil) else {
             return SupportedFileTypes.unknowen
        }
        let fileUTI = uti.takeRetainedValue()
        
        if UTTypeConformsTo(fileUTI, kUTTypeMP3){
            return SupportedFileTypes.audio
        }
        if  (UTTypeConformsTo(fileUTI, kUTTypeMovie) ||
            UTTypeConformsTo(fileUTI, kUTTypeQuickTimeMovie) ||
            UTTypeConformsTo(fileUTI, kUTTypeMPEG) ||
            UTTypeConformsTo(fileUTI, kUTTypeMPEG4)) {
            return SupportedFileTypes.video
        }
        return SupportedFileTypes.unknowen
    }
    
    static func copyFile(_ fileURL: URL, _ deleget: SoundsFilesMangerCopyDelegate){
        let fileType = checkFileType(fileURL)
        if fileType == .audio{
            coptyAudioFile(fileURL, deleget)
        }
        if fileType == .video{
            coptyVideoFile(fileURL, deleget)
        }
    }
    
    static func coptyAudioFile(_ fileURL: URL, _ deleget: SoundsFilesMangerCopyDelegate){
        let soundFileName = SoundsFilesManger.generateSoundFileName();
        let dstURL = SoundsFilesManger.getSoundURL(soundFileName)
        deleget.copyDidStart()
        DispatchQueue.global(qos: .background).async {
            let isSecuredURL = fileURL.startAccessingSecurityScopedResource() == true
            let coordinator = NSFileCoordinator()
            var error: NSError?
            coordinator.coordinate(readingItemAt: fileURL, options: [], error: &error) { (url) -> Void in
                do {
                    try FileManager.default.copyItem(at: fileURL, to: dstURL)
                }  catch let error {
                    print(error)
                    deleget.copyDidFaild(error)
                }
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }
            DispatchQueue.main.async {
                deleget.copyDidFinish(soundFileName)
            }
        }
    }
    
    static func coptyVideoFile(_ fileURL: URL, _ deleget: SoundsFilesMangerCopyDelegate){
        let temporal = getTemporalURL()
        let soundFileName = SoundsFilesManger.generateSoundFileName()
        let dstURL2 = SoundsFilesManger.getSoundURL(soundFileName)
        deleget.copyDidStart()
        DispatchQueue.global(qos: .background).async {
            let isSecuredURL = fileURL.startAccessingSecurityScopedResource() == true
            let coordinator = NSFileCoordinator()
            var error: NSError?
            coordinator.coordinate(readingItemAt: fileURL, options: [], error: &error) { (url) -> Void in
                do {
                    try FileManager.default.copyItem(at: fileURL, to: temporal)
                    var options = AKConverter.Options()
                        options.format = "m4a"
                        options.sampleRate = 48000
                        options.bitDepth = 24
                        let converter = AKConverter(inputURL: temporal, outputURL: dstURL2, options: options)
                        converter.start(completionHandler: { error in
                            deleteFile(temporal)
                            if let error = error {
                                DispatchQueue.main.async {
                                    deleget.copyDidFaild(error)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    deleget.copyDidFinish(soundFileName)
                                }
                            }
                        })
                  }  catch let error {
                      print(error)
                      deleget.copyDidFaild(error)
                  }
                
    
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }

        }
    }
}
