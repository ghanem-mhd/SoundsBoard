//
//  SiriExtension.swift
//  SBKit
//
//  Created by Mohammed Ghannm on 03.05.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation

public class SiriExtension{
    
    public static func getPlaySoundActivityName() -> String? {
        if let bundleId = Bundle.main.bundleIdentifier{
            return bundleId + ".play.sound"
        }
        return nil
    }
    
}
