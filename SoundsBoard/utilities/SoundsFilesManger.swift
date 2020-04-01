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
    case m4a
    case mp3
    case video
    case unknowen
}

protocol SoundsFilesMangerCopyDelegate: class {
    func copyDidStart()
    func convertDidStart()
    func copyAndConvertDidFinish(_ soundFileName: String)
    func copyDidFaild(_ erorr: Error, fileName: String)
}

protocol SoundsFilesMangerTrimDelegate: class {
    func trimDidFinshed()
    func trimDidFaild(_ erorr: Error)
}

class SoundsFilesManger{
    
    static func deleteSoundFile(_ soundFileName:String){
        deleteFile(getSoundURL(soundFileName))
    }
    
    static func deleteFile(_ url:URL){
        do {
            print("Deleting file at \(url)")
            if FileManager.default.fileExists(atPath: url.path){
                try FileManager.default.removeItem(at: url)
            }else{
                print("\(url) Not found")
            }
        } catch let error as NSError {
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
    
    static func getTemporalURL(_ extention:String = ".m4a") -> URL {
        let fileName = "\(NSUUID().uuidString).\(extention)"
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
            return SupportedFileTypes.mp3
        }
        if UTTypeConformsTo(fileUTI, kUTTypeMPEG4Audio){
            return SupportedFileTypes.m4a
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
        if fileType == .m4a{
            copyAudioFile(fileURL, deleget)
        }
        if fileType == .mp3{
            convertAndCopy(fileURL, deleget)
        }
        if fileType == .video{
            convertAndCopy(fileURL, deleget)
        }
    }
    
    static func copyAudioFile(_ fileURL: URL, _ deleget: SoundsFilesMangerCopyDelegate){
        let soundFileName = SoundsFilesManger.generateSoundFileName();
        let dstURL = SoundsFilesManger.getSoundURL(soundFileName)
        deleget.copyDidStart()
        DispatchQueue.global(qos: .background).async {
            let isSecuredURL = fileURL.startAccessingSecurityScopedResource() == true
            let coordinator = NSFileCoordinator()
            var error: NSError?
            coordinator.coordinate(readingItemAt: fileURL, options: [], error: &error) { (url) -> Void in
                do {
                    try FileManager.default.copyItem(at: url, to: dstURL)
                }  catch let error {
                    print(error)
                    deleget.copyDidFaild(error, fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                }
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }
            DispatchQueue.main.async {
                deleget.copyAndConvertDidFinish(soundFileName)
            }
        }
    }
    
    static func convertAndCopy(_ fileURL: URL, _ deleget: SoundsFilesMangerCopyDelegate){
        let temporal = getTemporalURL(fileURL.pathExtension)
        let soundFileName = SoundsFilesManger.generateSoundFileName()
        let dstURL2 = SoundsFilesManger.getSoundURL(soundFileName)
        deleget.copyDidStart()
        DispatchQueue.global(qos: .background).async {
            let isSecuredURL = fileURL.startAccessingSecurityScopedResource() == true
            let coordinator = NSFileCoordinator()
            var error: NSError?
            coordinator.coordinate(readingItemAt: fileURL, options: [], error: &error) { (url) -> Void in
                do {
                    try FileManager.default.copyItem(at: url, to: temporal)
                    var options = AKConverter.Options()
                        options.format = "m4a"
                        options.sampleRate = 48000
                        options.bitDepth = 24
                        let converter = AKConverter(inputURL: temporal, outputURL: dstURL2, options: options)
                        DispatchQueue.main.async {
                            deleget.convertDidStart()
                        }
                        converter.start(completionHandler: { error in
                            deleteFile(temporal)
                            if let error = error {
                                DispatchQueue.main.async {
                                    deleget.copyDidFaild(error,fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    deleget.copyAndConvertDidFinish(soundFileName)
                                }
                            }
                        })
                  }  catch let error {
                      print(error)
                    deleget.copyDidFaild(error,fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                  }
                
    
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }
            
        }
    }
    
    static func trimSound(soundFileName:String, startTime: Int, endTime:Int, delegate: SoundsFilesMangerTrimDelegate){
        AKSettings.enableLogging = true
        let temporal = getTemporalURL()
        let originalSoundFile = getSoundURL(soundFileName)
        do {
            try FileManager.default.copyItem(at: originalSoundFile, to: temporal)
            let audiofile = try AKAudioFile(forReading: temporal)
            audiofile.exportAsynchronously(name: soundFileName,
                                      baseDir: .documents,
                                      exportFormat: .m4a,
                                      fromSample: Int64(startTime * 44_100),
                                      toSample: Int64(endTime * 44_100))
            {_, exportError in
                if let error = exportError {
                    DispatchQueue.main.async {
                        delegate.trimDidFaild(error)
                    }
                  
                } else {
                    DispatchQueue.main.async {
                        delegate.trimDidFinshed()
                    }
                }
            }
        } catch let error {
            print(error)
        }
    }
}
