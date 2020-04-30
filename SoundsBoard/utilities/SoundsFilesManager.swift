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
import SBKit


public enum SupportedFileTypes {
    case m4a
    case mp3
    case video
    case unknown
}

public protocol SoundsFilesMangerCopyDelegate: class {
    func copyDidStart()
    func convertDidStart()
    func copyAndConvertDidFinish(_ soundFileName: String)
    func copyDidFailed(_ error: Error, fileName: String)
}

public protocol SoundsFilesMangerTrimDelegate: class {
    func trimDidFinished()
    func trimDidFailed(_ error: Error)
}

public extension SoundsFilesManger{
    
    static func checkFileType(_ url:URL) -> SupportedFileTypes{
        let urlExtension = NSURL(fileURLWithPath: url.path).pathExtension
        guard let uti = UTTypeCreatePreferredIdentifierForTag( kUTTagClassFilenameExtension,urlExtension! as CFString,nil) else {
            return SupportedFileTypes.unknown
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
        return SupportedFileTypes.unknown
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
                    deleget.copyDidFailed(error, fileName: fileURL.lastPathComponent + fileURL.pathExtension)
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
                                deleget.copyDidFailed(error,fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                            }
                        } else {
                            DispatchQueue.main.async {
                                deleget.copyAndConvertDidFinish(soundFileName)
                            }
                        }
                    })
                }  catch let error {
                    print(error)
                    deleget.copyDidFailed(error,fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                }
                
                
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }
            
        }
    }
    
    static func trimSound(soundFileName:String, startTime: Int, endTime:Int, delegate: SoundsFilesMangerTrimDelegate){
        AKSettings.enableLogging = false
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
                        delegate.trimDidFailed(error)
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        delegate.trimDidFinished()
                    }
                }
            }
        } catch let error {
            print(error)
        }
    }
    
    static func copySoundToAppContainer(soundObject:SoundObject){
        guard let soundFileName = soundObject.fileName, let appGroupURL = SoundsFilesManger.getAppGroupDirectory()  else {
            return
        }
        let appContainerURL = appGroupURL.appendingPathComponent(soundFileName)
        let originalSoundFileURL = getSoundURL(soundFileName)
        if soundObject.isFavorite{
            DispatchQueue.global(qos: .background).async {
                do {
                    try FileManager.default.copyItem(at: originalSoundFileURL, to: appContainerURL)
                } catch let error {
                    print(error)
                }
            }
        }else{
            deleteFile(appContainerURL)
        }
    }
}
