//
//  AlertsManager  .swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 28.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import UIKit

class AlertsManager{
    
    public static func showFileNotSuportedAlert(_ viewController: UIViewController){
        let alert = UIAlertController(title: "Opps", message: "The file type is not suported!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        viewController.present(alert, animated: true)
    }
    
    public static func showCopyFaildAlert(_ viewController: UIViewController){
        let alert = UIAlertController(title: "Opps", message: "The file can not be imported!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        viewController.present(alert, animated: true)
    }
}
