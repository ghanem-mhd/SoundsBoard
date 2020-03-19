//
//  SoundsFilesManger.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 11.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation

class SoundsFilesManger{
    
    static func getSoundURL(_ soundGeneratedName:String) -> URL {
        return getDocumentsDirectory().appendingPathComponent(soundGeneratedName)
    }
    
    static func generateSoundName() -> String {
        return "\(NSUUID().uuidString).m4a"
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func deleteSoundFile(_ soundGeneratedName:String) -> Bool{
        do {
            try FileManager.default.removeItem(at: getSoundURL(soundGeneratedName))
            return true
        } catch let error as NSError {
            NSLog("error: \(error)")
        }
        return false
    }
}
