//
//  TodayViewController.swift
//  SBWidget
//
//  Created by Mohammad Ghanem on 11.04.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import UIKit
import NotificationCenter
import SBKit
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    var collectionView: UICollectionView!
    var cellId = "Cell"
    var moc: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<SoundObject>?
    
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    let itemsPerRow: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // save ManagedObjectContext in class attribute
        self.moc = CoreDataManager.shared.persistentContainer.viewContext
        
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInsets
    
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SoundCollectionCellView.self, forCellWithReuseIdentifier: cellId)
        self.view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints{ (make) -> Void in
            make.edges.equalTo(self.view.snp.edges)
        }
        
        collectionView.backgroundColor = nil
        initializeFetchedResultsController()
    }
    
    func initializeFetchedResultsController() {
        let fetchRequest = CoreDataManager.shared.getWidgetFetchReqest()
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

        return CGSize(width: widthPerItem, height: 90)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! SoundCollectionCellView
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
            collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.endEditing(true)
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
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
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
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: .max, height: 310)
        }else{
            self.preferredContentSize = CGSize(width: .max, height: 110)
        }
    }
}
