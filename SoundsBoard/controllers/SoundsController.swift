//
//  FavoriteControllers.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 22.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//
import UIKit


let reuseIdentifier = "CellIdentifer";
import Foundation
import SnapKit
import CoreData
import SwiftySound
import SBKit


class SoundsController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    var collectionview: UICollectionView!
    var cellId = "Cell"
    var moc: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<SoundObject>?
    
    let sectionInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    let itemsPerRow: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.moc = CoreDataManager.shared.persistentContainer.viewContext
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInsets
        
        collectionview = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionview.dataSource = self
        collectionview.delegate = self
        collectionview.register(SoundCollectionCellView.self, forCellWithReuseIdentifier: cellId)
        collectionview.showsVerticalScrollIndicator = false
        collectionview.backgroundColor = .white
        collectionview.dragInteractionEnabled = true
        self.view.addSubview(collectionview)
        
        initializeFetchedResultsController()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        collectionview.addGestureRecognizer(longPressGesture)
    }
    
    func initializeFetchedResultsController() {
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: "SoundObject")
        let favoriteSort = NSSortDescriptor(key: "isFavorite", ascending: false)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [favoriteSort, nameSort]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        guard let controller = fetchedResultsController else{
            return
        }
        controller.delegate = self
        do {
            try controller.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let controller = fetchedResultsController, let sections = controller.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionview.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! SoundCollectionCellView
        guard let controller = fetchedResultsController else {
            fatalError("Attempt to configure cell without a managed object")
        }
        let soundObject = controller.object(at: indexPath)
        cell.update(soundObject)
        return cell
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            collectionview.insertItems(at: [newIndexPath!])
        case .delete:
            collectionview.deleteItems(at: [indexPath!])
        case .update:
            collectionview.reloadItems(at: [indexPath!])
        case .move:
            collectionview.moveItem(at: indexPath!, to: newIndexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionview.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let controller = fetchedResultsController else {
            fatalError("Attempt to configure cell without a managed object")
        }
        let clickedSound = controller.object(at: indexPath)
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
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let indexPath = self.collectionview.indexPathForItem(at: gesture.location(in: collectionview))
        if let indexPath = indexPath {
            let touchedSound = fetchedResultsController?.object(at: indexPath)
            if let soundName = touchedSound?.fileName{
                let activityVC = UIActivityViewController(activityItems: [SoundsFilesManger.getSoundURL(soundName)],applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = self.view
                self.present(activityVC, animated: true, completion: nil)
            }
        } else {
            print("Could not find index path")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard fetchedResultsController != nil else {
            fatalError("No fetchedResultsController")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AudioPlayer.sharedInstance.stop()
    }
    
}





