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

class MoreController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var tableView:UITableView?
    var moc: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<SoundObject>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.moc = CoreDataManager.shared.persistentContainer.viewContext
        tableView = UITableView(frame: self.view.frame)
        if let tb = tableView{
            tb.rowHeight = 44
            tb.dataSource = self
            tb.delegate = self
            tb.register(SoundTableCellView.self, forCellReuseIdentifier: "SoundCellView")
            self.view.addSubview(tb)
        }
        initializeFetchedResultsController()
    }
    
    func initializeFetchedResultsController() {
        let fetchRequest = CoreDataManager.shared.getMoreControllerFetchReqest()
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundCellView", for: indexPath) as! SoundTableCellView
        guard let soundObject = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.update(soundObject)
        cell.favoriteClick = {
            self.toggleIsFavorite(soundObject)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView?.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        default:
            break
        }
    }
    
    var changeIsUserDriven = false
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if (changeIsUserDriven) {
        }
        switch type {
        case .insert:
            tableView?.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView?.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            let indexPath = indexPath!
            let newIndexPath = newIndexPath!
            print("indexPath \(indexPath.row)")
            print("newIndexPath \(newIndexPath.row)")
            tableView?.moveRow(at: indexPath, to: newIndexPath)
        default:
            break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let soundObject = self.fetchedResultsController?.object(at: indexPath) else {
                fatalError("Attempt to fetch non existed item")
            }
            do {
                moc.delete(soundObject)
                try moc.save()
                
                moc.refreshAllObjects()
            } catch let error as NSError {
                print("Error while deleting entry: \(error.userInfo)")
            }
        }
    }
    
    public func onEditButtonClicked(_ editButton: UIBarButtonItem){
        if let tb = tableView{
            tb.setEditing(!tb.isEditing, animated: true)
            editButton.title = tb.isEditing ? "Done" : "Edit"
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = fetchedResultsController.object(at: indexPath)
        let addEditSoundController = AddEditSoundController()
        addEditSoundController.state = .Edit
        addEditSoundController.editableSound = object
        self.navigationController!.pushViewController(addEditSoundController, animated: true)
        
        self.tableView?.deselectRow(at: indexPath, animated: true)
    }
    
    func toggleIsFavorite(_ soundObject: SoundObject){
        if !soundObject.isFavorite && CoreDataManager.shared.maxFavoriteReached(){
            AlertsManager.showMaxFavoriteAlert(self)
            return
        }
        soundObject.isFavorite = !soundObject.isFavorite
        do {
            try moc.save()
        } catch let error as NSError {
            print(error)
            moc.rollback()
        }
    }
}

