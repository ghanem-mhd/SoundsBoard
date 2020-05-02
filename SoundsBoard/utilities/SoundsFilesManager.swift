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
    
    static func copyFile(_ fileURL: URL, _ delegate: SoundsFilesMangerCopyDelegate){
        let fileType = checkFileType(fileURL)
        if fileType == .m4a{
            copyAudioFile(fileURL, delegate)
        }
        if fileType == .mp3{
            convertAndCopy(fileURL, delegate)
        }
        if fileType == .video{
            extractAudioAndExport(fileURL, delegate)
        }
    }
    
    static func copyAudioFile(_ fileURL: URL, _ delegate: SoundsFilesMangerCopyDelegate){
        let soundFileName = SoundsFilesManger.generateSoundFileName();
        let dstURL = SoundsFilesManger.getSoundURL(soundFileName)
        delegate.copyDidStart()
        DispatchQueue.global(qos: .background).async {
            let isSecuredURL = fileURL.startAccessingSecurityScopedResource() == true
            let coordinator = NSFileCoordinator()
            var error: NSError?
            coordinator.coordinate(readingItemAt: fileURL, options: [], error: &error) { (url) -> Void in
                do {
                    try FileManager.default.copyItem(at: url, to: dstURL)
                }  catch let error {
                    print(error)
                    delegate.copyDidFailed(error, fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                }
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }
            DispatchQueue.main.async {
                delegate.copyAndConvertDidFinish(soundFileName)
            }
        }
    }
    
    static func convertAndCopy(_ fileURL: URL, _ delegate: SoundsFilesMangerCopyDelegate){
        let temporal = getTemporalURL(fileURL.pathExtension)
        let soundFileName = SoundsFilesManger.generateSoundFileName()
        let dstURL2 = SoundsFilesManger.getSoundURL(soundFileName)
        delegate.copyDidStart()
        DispatchQueue.global(qos: .background).async {
            let isSecuredURL = fileURL.startAccessingSecurityScopedResource() == true
            let coordinator = NSFileCoordinator()
            var error: NSError?
            coordinator.coordinate(readingItemAt: fileURL, options: [], error: &error) { (url) -> Void in
                do {
                    try FileManager.default.copyItem(at: url, to: temporal)
                    var options = AKConverter.Options()
                    options.eraseFile = true
                    options.format = "m4a"
                    options.sampleRate = 48000
                    options.bitDepth = 24
                    let converter = AKConverter(inputURL: temporal, outputURL: dstURL2, options: options)
                    DispatchQueue.main.async {
                        delegate.convertDidStart()
                    }
                    converter.start(completionHandler: { error in
                        deleteFile(temporal)
                        if let error = error {
                            DispatchQueue.main.async {
                                delegate.copyDidFailed(error,fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                            }
                        } else {
                            DispatchQueue.main.async {
                                delegate.copyAndConvertDidFinish(soundFileName)
                            }
                        }
                    })
                }  catch let error {
                    print(error)
                    delegate.copyDidFailed(error,fileName: fileURL.lastPathComponent + fileURL.pathExtension)
                }
                
                
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }
            
        }
    }
    
    
    static func extractAudioAndExport(_ sourceUrl: URL, _ delegate: SoundsFilesMangerCopyDelegate) {
        delegate.copyDidStart()
        delegate.convertDidStart()
        let temporal = getTemporalURL(sourceUrl.pathExtension)
        let soundFileName = SoundsFilesManger.generateSoundFileName()
        let dstURL2 = SoundsFilesManger.getSoundURL(soundFileName)
        let isSecuredURL = sourceUrl.startAccessingSecurityScopedResource() == true
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(readingItemAt: sourceUrl, options: [], error: &error) { (url) -> Void in
            // Create a composition
            let composition = AVMutableComposition()
            do {
                try FileManager.default.copyItem(at: url, to: temporal)
                let asset = AVURLAsset(url: temporal)
                guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
                guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
                let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTime(seconds: 20, preferredTimescale: 1))
                try audioCompositionTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: CMTime.zero)
            } catch {
                print(error)
                delegate.copyDidFailed(error,fileName: sourceUrl.lastPathComponent)
            }
            // Create an export session
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
            exportSession.outputFileType = AVFileType.m4a
            exportSession.outputURL = dstURL2
            
            // Export file
            exportSession.exportAsynchronously {
                if let e = exportSession.error{
                    print(e)
                    delegate.copyDidFailed(e,fileName: sourceUrl.lastPathComponent)
                }
                guard case exportSession.status = AVAssetExportSession.Status.completed else { return }
                DispatchQueue.main.async {
                    delegate.copyAndConvertDidFinish(soundFileName)
                }
            }
        }
        if (isSecuredURL) {
            sourceUrl.stopAccessingSecurityScopedResource()
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
                                           baseDir: .custom,
                                           exportFormat: .m4a,
                                           fromSample: Int64(startTime * 44_100),
                                           toSample: Int64(endTime * 44_100))
            {_, exportError in
                deleteFile(temporal)
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
