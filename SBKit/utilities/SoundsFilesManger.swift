//
//  SoundsFilesManger.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 11.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import MobileCoreServices
import AVFoundation

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
    
    public static func getAppGroupDirectorySoundURL(_ soundFileName:String) -> URL {
        return getAppGroupDirectory()!.appendingPathComponent(soundFileName) //TODO
    }
    
    public static func generateNameWithSameExtension(_ url: URL) -> String{
        return "\(NSUUID().uuidString).\(url.pathExtension)"
    }
    
    public static func copyURLFromShareExtension2(_ data: NSData, _ delegate: SoundsFilesMangerShareDelegate){
        guard let appGroupURL = SoundsFilesManger.getAppGroupDirectory()  else {
            return
        }
        let mediaName = "\(NSUUID().uuidString).mov"
        let mediaURL = appGroupURL.appendingPathComponent(mediaName)
        DispatchQueue.global(qos: .background).async {
            do {
                try data.write(to: mediaURL)
                delegate.copyDidFinish(mediaName)
            } catch let error {
                delegate.copyDidFailed(error)
            }
        }
    }
    
    public static func copyURLFromShareExtension(_ url: URL, _ delegate: SoundsFilesMangerShareDelegate){
        guard let appGroupURL = SoundsFilesManger.getAppGroupDirectory()  else {
            return
        }
        let mediaName = generateNameWithSameExtension(url)
        let mediaURL = appGroupURL.appendingPathComponent(mediaName)
        DispatchQueue.global(qos: .background).async {
            do {
                try FileManager.default.copyItem(at: url, to: mediaURL)
                //test(source: url, target: mediaURL)
                delegate.copyDidFinish(mediaName)
            } catch let error {
                delegate.copyDidFailed(error)
            }
        }
    }
}
    


public protocol SoundsFilesMangerShareDelegate: class {
    func copyDidFinish(_ fileName: String)
    func copyDidFailed(_ error: Error)
}
