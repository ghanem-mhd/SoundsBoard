//
//  AllSoundsController.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 24.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import SBKit

class MoreController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var tableView:UITableView!
    private var soundsList : [SoundObject] = []
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNotifications()
        setUpReferchControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateTableViewData()
    }
    
    private func setUpTableView(){
        tableView = UITableView(frame: self.view.frame)
        tableView.rowHeight = 44
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundTableCellView.self, forCellReuseIdentifier: "SoundCellView")
        self.view.addSubview(tableView)
    }
    
    private func setUpNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(onSoundSaved(_:)), name: Constants.soundSavedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func setUpReferchControl(){
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
         return soundsList.count
     } else {
         return 0
     }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundCellView", for: indexPath) as! SoundTableCellView
        let soundObject =  self.soundsList[indexPath.row]
        cell.update(soundObject)
        cell.favoriteClick = {
            CoreDataManager.shared.toggleIsFavorite(soundObject, maxFavoriteReached: {
                AlertsManager.showMaxFavoriteAlert(self)
            })
            if let cell = tableView.cellForRow(at: indexPath) as? SoundTableCellView {
                cell.update(soundObject)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let isDeleted = CoreDataManager.shared.deleteSound(deletedSound: soundsList[indexPath.row])
            if isDeleted{
                soundsList.remove(at: indexPath.row)
                tableView.reloadData()
            }
        }
    }
    
    public func onEditButtonClicked(_ editButton: UIBarButtonItem){
        tableView.setEditing(!tableView.isEditing, animated: true)
        editButton.title = tableView.isEditing ? "Done" : "Edit"
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = self.soundsList[indexPath.row]
        let addEditSoundController = AddEditSoundController()
        addEditSoundController.state = .Edit
        addEditSoundController.editableSound = object
        if let controller = navigationController{
            controller.pushViewController(addEditSoundController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedSound = soundsList.remove(at: sourceIndexPath.row)
        soundsList.insert(movedSound, at: destinationIndexPath.row)
        tableView.reloadData()
        CoreDataManager.shared.updateSoundsOrder(soundsList: soundsList)
    }
    
    @objc func onSoundSaved(_ notification:Notification) {
        print("onSoundSaved More Controller")
        if let data = notification.userInfo as? [String: SoundObject]{
            if let savedSound = data[Constants.soundSavedUserInfo]{
                soundsList.append(savedSound)
                tableView.reloadData()
            }
        }
    }
    
    @objc func willEnterForeground() {
        updateTableViewData()
    }
    
    @objc private func refreshData(_ sender: Any) {
        updateTableViewData()
        refreshControl.endRefreshing()
    }
    
    private func updateTableViewData(){
        if let sounds = CoreDataManager.shared.getAllSoundsForMoreController(){
            soundsList = sounds
         }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

