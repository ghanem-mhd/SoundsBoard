//
//  VolumeManager.swift
//  SBKit
//
//  Created by Mohammad Ghanem on 19.04.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation


public class VolumeManager{
    
    public static let defaultVolume          = 1 // The Mid
    public static let volumesTitles         = ["Low","Mid","High"]
    public static let volumesValues         = [volumesTitles[0]: Float(0.25), volumesTitles[1]: Float(0.50), volumesTitles[2]: Float(1.0)]
    
    public static func getVolumeValue(_ index:Int)-> Float{
        let volumeKey = VolumeManager.volumesTitles[index]
        if let volumeValue = VolumeManager.volumesValues[volumeKey]{
            return volumeValue
        }else{
            return Float(1.0)
        }
    }
    
    public static func getVolumeIndex(_ volumeValue:Float) -> Int{
        for (key, value) in volumesValues {
            if value == volumeValue{
                return volumesTitles.firstIndex(of: key)!
            }
        }
        return defaultVolume
    }
}
