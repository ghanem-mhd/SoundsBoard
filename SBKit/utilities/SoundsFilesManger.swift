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

public enum SupportedFileTypes {
    case m4a
    case mp3
    case mov
    case video
    case wav
    case unknown
}

public protocol SoundsFilesMangerCopyDelegate: class {
    func copyDidStart()
    func convertDidStart()
    func copyAndConvertDidFinish(_ soundFileName: String, _ temporal: URL?)
    func copyDidFailed(_ error: Error, fileName: String)
}

public protocol SoundsFilesMangerTrimDelegate: class {
    func trimDidFinished()
    func trimDidFailed(_ error: Error)
}

public class SoundsFilesManger{
    
    public static func deleteSoundFile(_ soundFileName:String){
        deleteFile(getSoundURL(soundFileName))
    }
    
    public static func deleteFile(_ url:URL){
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
    
    public static func getFilesFromDocumentsFolder() -> [String]?{
        let fileManager = FileManager.default;
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        return try? fileManager.contentsOfDirectory(atPath:docs)
    }
    
    public static func getFilesFromDocumentsFolder2() -> [String]?{
        return try? FileManager.default.contentsOfDirectory(atPath:getAppGroupDirectory()!.path)
    }
    
    public static func getSoundURL(_ soundFileName:String) -> URL {
        if let appGroupDir = getAppGroupDirectory(){
            return appGroupDir.appendingPathComponent(soundFileName)
        }else{
            return getDocumentsDirectory().appendingPathComponent(soundFileName)
        }
    }
    
    public static func getTemporalURL(_ extensionName :String = ".m4a") -> URL {
        let fileName = "\(NSUUID().uuidString).\(extensionName)"
        return getSoundURL(fileName)
    }
    
    public static func generateSoundFileName() -> String {
        return "\(NSUUID().uuidString).m4a"
    }
    
    public static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public static func getAppGroupDirectory() -> URL? {
        let appGroup = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)
        return appGroup?.appendingPathComponent("Library", isDirectory:  true)
    }

    static func getDownloadCasheDirectory() -> URL {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: cachePath).appendingPathComponent("downloads")
    }
    
    static func clearDownloadCasheDirectory(){
        do {
            let fileManager = FileManager.default
            let items = try fileManager.contentsOfDirectory(atPath: getDownloadCasheDirectory().path)
            for filePath in items {
                print("Deleting \(filePath)")
                try fileManager.removeItem(atPath: getDownloadCasheDirectory().path + "/" + filePath)
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    public static func getAppGroupDirectorySoundURL(_ soundFileName:String) -> URL {
        return getAppGroupDirectory()!.appendingPathComponent(soundFileName) //TODO
    }
    
    public static func generateNameWithSameExtension(_ url: URL) -> String{
        return "\(NSUUID().uuidString).\(url.pathExtension)"
    }
    
    public static func checkFileType(_ url:URL) -> SupportedFileTypes{
        let urlExtension = NSURL(fileURLWithPath: url.path).pathExtension
        guard let uti = UTTypeCreatePreferredIdentifierForTag( kUTTagClassFilenameExtension,urlExtension! as CFString,nil) else {
            return SupportedFileTypes.unknown
        }
        let fileUTI = uti.takeRetainedValue()
        if UTTypeConformsTo(fileUTI, kUTTypeMP3){
            return SupportedFileTypes.mp3
        }
        if UTTypeConformsTo(fileUTI, kUTTypeWaveformAudio){
            return SupportedFileTypes.wav
        }
        if UTTypeConformsTo(fileUTI, kUTTypeMPEG4Audio){
            return SupportedFileTypes.m4a
        }
        if UTTypeConformsTo(fileUTI, kUTTypeQuickTimeMovie){
            return SupportedFileTypes.mov
        }
        if (UTTypeConformsTo(fileUTI, kUTTypeMPEG) ||
            UTTypeConformsTo(fileUTI, kUTTypeMPEG4)) {
            return SupportedFileTypes.video
        }
        return SupportedFileTypes.unknown
    }
    
    public static func copyFile(_ fileURL: URL, _ delegate: SoundsFilesMangerCopyDelegate){
        let fileType = checkFileType(fileURL)
        if fileType == .m4a{
            copyAudioFile(fileURL, delegate)
        }
        if fileType == .mp3 || fileType == .wav{
            convertAndCopy(fileURL, delegate)
        }
        if fileType == .video{
            convertAndCopy(fileURL, delegate)
        }
        if fileType == .mov{
            convertAndCopyMov(fileURL, delegate)
        }
    }
    
    public static func copyAudioFile(_ fileURL: URL, _ delegate: SoundsFilesMangerCopyDelegate){
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
                delegate.copyAndConvertDidFinish(soundFileName, nil)
            }
        }
    }
    
    public static func convertAndCopy(_ fileURL: URL, _ delegate: SoundsFilesMangerCopyDelegate){
        AKSettings.enableLogging = false
        let temporal = getTemporalURL(fileURL.pathExtension)
        let soundFileName = SoundsFilesManger.generateSoundFileName()
        let soundFileURL = SoundsFilesManger.getSoundURL(soundFileName)
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
                    let converter = AKConverter(inputURL: temporal, outputURL: soundFileURL, options: options)
                    DispatchQueue.main.async {
                        delegate.convertDidStart()
                    }
                    converter.start(completionHandler: { error in
                        if let error = error {
                            DispatchQueue.main.async {
                                delegate.copyDidFailed(error,fileName: fileURL.lastPathComponent)
                            }
                        } else {
                            DispatchQueue.main.async {
                                delegate.copyAndConvertDidFinish(soundFileName, temporal)
                            }
                        }
                    })
                }  catch let error {
                    print(error)
                    delegate.copyDidFailed(error,fileName: fileURL.lastPathComponent)
                }
            }
            if (isSecuredURL) {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
    }
    
    
    public static func convertAndCopyMov(_ sourceUrl: URL, _ delegate: SoundsFilesMangerCopyDelegate) {
        delegate.copyDidStart()
        delegate.convertDidStart()
        let temporal = getTemporalURL(sourceUrl.pathExtension)
        let soundFileName = SoundsFilesManger.generateSoundFileName()
        let soundFileURL = SoundsFilesManger.getSoundURL(soundFileName)
        let composition = AVMutableComposition()
        do {
            try FileManager.default.copyItem(at: sourceUrl, to: temporal)
            let asset = AVURLAsset(url: temporal)
            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
            delegate.copyDidFailed(error,fileName: sourceUrl.lastPathComponent)
        }
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = soundFileURL
        exportSession.exportAsynchronously {
            if let e = exportSession.error{
                print(e)
                delegate.copyDidFailed(e,fileName: sourceUrl.lastPathComponent)
            }
            guard case exportSession.status = AVAssetExportSession.Status.completed else { return }
            DispatchQueue.main.async {
                delegate.copyAndConvertDidFinish(soundFileName, temporal)
            }
        }
    }
    
    
    public static func trimSound(soundFileName:String, startTime: Int, endTime:Int, delegate: SoundsFilesMangerTrimDelegate){
        AKSettings.enableLogging = false
        let temporal = getTemporalURL()
        let originalSoundFile = getSoundURL(soundFileName)
        do {
            try FileManager.default.copyItem(at: originalSoundFile, to: temporal)
            let audioFile = try AKAudioFile(forReading: temporal)
            audioFile.exportAsynchronously(name: soundFileName,
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
    
    public static func copySoundToAppContainer(soundObject:SoundObject){
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
    
    public static func getThumbnailImageFromVideoUrl(url: URL?, thumbnailTime:Int64, completion: @escaping ((_ image: UIImage?)->Void)) {
        guard let videoURL = url else {
            completion(nil)
            return
        }
        DispatchQueue.global().async {
            let avAssetImageGenerator = AVAssetImageGenerator(asset: AVAsset(url: videoURL))
            avAssetImageGenerator.appliesPreferredTrackTransform = true
            let thumbnailTime = CMTimeMake(value: thumbnailTime, timescale: 1)
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
                let thumbImage = UIImage(cgImage: cgThumbImage)
                DispatchQueue.main.async {
                    completion(thumbImage)
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
