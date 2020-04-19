//
//  SiriExtension.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 19.04.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation

public class SiriExtension{
    
    public static func getPlaySoundAcivityName() -> String? {
        if let bundleId = Bundle.main.bundleIdentifier{
            return bundleId + ".play.sound"
        }
        return nil
    }
    
}
