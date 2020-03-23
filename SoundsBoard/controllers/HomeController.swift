//
//  ViewController.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 05.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import SwiftySound

class HomeController: UITabBarController {
    
    var moc : NSManagedObjectContext!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // getting appDelegate's reference
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        self.moc = appDelegate.persistentContainer.viewContext
                 
        do {
            let fetchRequest = NSFetchRequest<SoundObject>(entityName: "SoundObject")
            let allSound = try moc.fetch(fetchRequest)
            allSound.forEach { (sound) in

            }
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
    }
}

