//
//  AlertsManager.swift
//  SBKit
//
//  Created by Mohammed Ghannm on 03.05.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import UIKit

public class AlertsManager{
    
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
    
    public static func getActivityIndicatorAlert() -> UIAlertController{
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        alert.view.addSubview(loadingIndicator)
        return alert
    }
}
