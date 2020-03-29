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


class FavoriteController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
   
    var collectionview: UICollectionView!
    var cellId = "Cell"
    var moc: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<SoundObject>?

    
    private let spacing:CGFloat = 16.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        // save ManagedObjectContext in class attribute
        self.moc = appDelegate.persistentContainer.viewContext

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing

        
        collectionview = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionview.dataSource = self
        collectionview.delegate = self
        collectionview.register(FavoriteCellView.self, forCellWithReuseIdentifier: cellId)
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
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSort]
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
        let numberOfItemsPerRow:CGFloat = 2
        let spacingBetweenCells:CGFloat = 16
    
        let totalSpacing = (2 * self.spacing) + ((numberOfItemsPerRow - 1) * spacingBetweenCells) //Amount of total spacing in a row
        let width = (collectionView.frame.size.width - totalSpacing)/numberOfItemsPerRow
        return CGSize(width: width, height: width)
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
        let cell = collectionview.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FavoriteCellView
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
        if let soundGeneratedName = clickedSound.generatedName{
            Sound.play(url: SoundsFilesManger.getSoundURL(soundGeneratedName))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionview.indexPathForItem(at: gesture.location(in: collectionview)) else {
                break
            }
            collectionview.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionview.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionview.endInteractiveMovement()
        default:
            collectionview.cancelInteractiveMovement()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let controller = fetchedResultsController else {
            fatalError("No fetchedResultsController")
        }
    }

}




