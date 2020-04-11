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
import SBKit

class HomeController: UITabBarController,UITabBarControllerDelegate {
    
    var moc : NSManagedObjectContext!
    lazy var editButton     = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(editButtonClicked))


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        print(SoundsFilesManger.getFilesFromDocumentsFolder() ?? "")
        
        self.delegate = self
        

        self.moc = CoreDataManager.shared.persistentContainer.viewContext
        
        self.navigationItem.leftBarButtonItem = editButton
        editButtonToggle(isEnabled: false)
                 
        do {
            let fetchRequest = NSFetchRequest<SoundObject>(entityName: "SoundObject")
            let allSound = try moc.fetch(fetchRequest)
            allSound.forEach { (sound) in

            }
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
    }
    
    @objc func editButtonClicked(_ sender: Any){
        if let controller = selectedViewController as? AllSoundsController{
            controller.onEditButtonClicked(editButton)
        }
    }
    
    // UITabBarDelegate
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }

    // UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is AllSoundsController{
            editButtonToggle(isEnabled: true)
        }
        
        if viewController is FavoriteController{
            editButtonToggle(isEnabled: false)
        }
    }
    
    @IBAction func onAddButtonClicked(_ sender: Any) {
        let addEditSoundController = AddEditSoundController()
        addEditSoundController.state = .Add
        self.navigationController!.pushViewController(addEditSoundController, animated: true)
    }
    
    private func editButtonToggle(isEnabled:Bool){
        if isEnabled{
            self.editButton.isEnabled = true
            self.editButton.tintColor    = nil
        }else{
            self.editButton.isEnabled = false
            self.editButton.tintColor    = .clear
        }
    }
}

