//
//  AlertsManager  .swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 28.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import UIKit
import SBKit

class AlertsManager{
    
    public static func showAlert(_ viewController: UIViewController, _ title: String, _ message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        viewController.present(alert, animated: true)
    }
    
    public static func showFileNotSupportedAlert(_ viewController: UIViewController){
        AlertsManager.showAlert(viewController, "Opps", "The file type is not supported!")
    }
    
    public static func showImportFailedAlert(_ viewController: UIViewController, fileName: String){
        AlertsManager.showAlert(viewController, "Opps", "Can't import \(fileName)!")
    }
    
    public static func showPlayingAlert(_ viewController: UIViewController){
        AlertsManager.showAlert(viewController, "Opps", "Unable to play the sound!")
    }
    
    public static func showMaxFavoriteAlert(_ viewController: UIViewController){
        AlertsManager.showAlert(viewController, "Opps", "Maximum favourite sounds is \(Constants.maximumFavoriteSounds).")
    }
    
    
}
