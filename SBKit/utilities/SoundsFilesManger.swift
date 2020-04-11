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
    
    public static func getFilesFromDocumentsFolder() -> [String]?
    {
        let fileMngr = FileManager.default;
        let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        return try? fileMngr.contentsOfDirectory(atPath:docs)
    }
    
    public static func getSoundURL(_ soundFileName:String) -> URL {
        return getDocumentsDirectory().appendingPathComponent(soundFileName)
    }
    
    public static func getTemporalURL(_ extention:String = ".m4a") -> URL {
        let fileName = "\(NSUUID().uuidString).\(extention)"
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }
    
    public static func generateSoundFileName() -> String {
        return "\(NSUUID().uuidString).m4a"
    }
    
    public static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
