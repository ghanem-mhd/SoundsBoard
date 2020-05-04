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
    
    lazy var editButton = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(editButtonClicked))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        print(SoundsFilesManger.getFilesFromDocumentsFolder2() ?? "")
        
        self.delegate = self
        
        
        self.navigationItem.leftBarButtonItem = editButton
        editButtonToggle(isEnabled: false)
    }
    
    @objc func editButtonClicked(_ sender: Any){
        if let controller = selectedViewController as? MoreController{
            controller.onEditButtonClicked(editButton)
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is MoreController{
            editButtonToggle(isEnabled: true)
        }
        
        if viewController is SoundsController{
            editButtonToggle(isEnabled: false)
        }
    }
    
    @IBAction func onAddButtonClicked(_ sender: Any) {
        let addEditSoundController = AddEditSoundController()
        addEditSoundController.state = .Add
        if let navCont = self.navigationController{
            navCont.pushViewController(addEditSoundController, animated: true)
        }
    }
    
    private func editButtonToggle(isEnabled:Bool){
        if isEnabled{
            self.editButton.isEnabled = true
            self.editButton.tintColor = nil
        }else{
            self.editButton.isEnabled = false
            self.editButton.tintColor = .clear
        }
    }
}

