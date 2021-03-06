//
//  Constants.swift
//  SBKit
//
//  Created by Mohammad Ghanem on 17.04.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation

public struct Constants{
    
    public static let modelName             = "SoundsBoard"
    public static let appGroupID            = "group.SoundsBoard"
    public static let maximumFavoriteSounds = 9
    public static let itemsPerRow           = 3
    
    
    public static let soundSavedNotification    = Notification.Name("soundSaved")
    public static let soundSavedUserInfo        = "savedSound"
}
