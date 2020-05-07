//
//  FavoriteControllers.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 22.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//
import UIKit
import Foundation
import SnapKit
import CoreData
import SwiftySound
import SBKit


class SoundsController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    private var collectionView: UICollectionView!
    private var soundsList : [SoundObject] = []
    private let refreshControl = UIRefreshControl()
    private let sectionInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNotification()
        setUpCollectionView()
        setUpReferchControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateCollectionViewData()
    }
    
    private func setUpNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(onSoundSaved(_:)), name: Constants.soundSavedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func setUpCollectionView(){
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInsets
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SoundCollectionCellView.self, forCellWithReuseIdentifier: "Cell")
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.dragInteractionEnabled = true
        self.view.addSubview(collectionView)
    }
    
    private func setUpReferchControl(){
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (CGFloat(Constants.itemsPerRow) + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / CGFloat(Constants.itemsPerRow)
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return soundsList.count
        } else {
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! SoundCollectionCellView
        let soundObject = soundsList[indexPath.row]
        cell.update(soundObject)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let clickedSound = soundsList[indexPath.row]
        let cell = collectionView.cellForItem(at: indexPath)
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        cell?.alpha = 0.8
        }) { (completed) in
            UIView.animate(withDuration: 0.3,
                           animations: {
                            cell?.alpha = 1
            })
        }
        
        if let soundGeneratedName = clickedSound.fileName{
            AudioPlayer.sharedInstance.play(soundFileName: soundGeneratedName, volume: clickedSound.volume)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AudioPlayer.sharedInstance.stop()
    }
    
    @objc func onSoundSaved(_ notification:Notification) {
        print("onSoundSaved Sounds Controller")
        if let data = notification.userInfo as? [String: SoundObject]{
            if let savedSound = data[Constants.soundSavedUserInfo]{
                soundsList.append(savedSound)
                collectionView?.reloadData()
            }
        }
    }
    
    @objc func willEnterForeground() {
        updateCollectionViewData()
    }
    
    @objc private func refreshData(_ sender: Any) {
        updateCollectionViewData()
        self.refreshControl.endRefreshing()
    }
    
    private func updateCollectionViewData(){
        if let sounds = CoreDataManager.shared.getAllSoundsForSoundsController(){
            soundsList = sounds
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu(soundObject: self.soundsList[indexPath.row])
        })
    }
    
    @available(iOS 13.0, *)
    func makeContextMenu(soundObject:SoundObject) -> UIMenu {
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { action in
            self.shareSound(soundObject: soundObject)
        }
        let edit = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) { action in
            self.editSound(soundObject: soundObject)
        }
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
            self.deleteSound(soundObject: soundObject)
        }
        if let soundName = soundObject.name{
            return UIMenu(title: soundName, children: [edit, share, delete])
        }else{
            return UIMenu(title: "Main Menu", children: [edit, share, delete])
        }
    }
    
    private func shareSound(soundObject:SoundObject){
        if let soundName = soundObject.fileName{
            let activityVC = UIActivityViewController(activityItems: [SoundsFilesManger.getSoundURL(soundName)],applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func editSound(soundObject:SoundObject){
        let addEditSoundController = AddEditSoundController()
        addEditSoundController.state = .Edit
        addEditSoundController.editableSound = soundObject
        if let controller = self.navigationController{
            controller.pushViewController(addEditSoundController, animated: true)
        }
    }
    
    private func deleteSound(soundObject:SoundObject){
        let isDeleted = CoreDataManager.shared.deleteSound(deletedSound: soundObject)
        if isDeleted{
           updateCollectionViewData()
        }
    }
}





