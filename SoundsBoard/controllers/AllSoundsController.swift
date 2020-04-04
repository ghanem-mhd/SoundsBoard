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

class AllSoundsController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var tableView:UITableView?
    var fetchRequest: NSFetchRequest<SoundObject>?
    var moc: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<SoundObject>!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // getting the appDelegate's reference
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        self.moc = appDelegate.persistentContainer.viewContext
        tableView = UITableView(frame: self.view.frame)
        if let tb = tableView{
            tb.dataSource = self
            tb.delegate = self
            tb.register(SoundCellView.self, forCellReuseIdentifier: "SoundCellView")
            self.view.addSubview(tb)
        }
        initializeFetchedResultsController()
    }
    
    // Creates a NSFetchRequest and NSFetchedResultsController and fetches the data
    func initializeFetchedResultsController() {
        
        // create fetch request and saves it in an attribute
        self.fetchRequest = NSFetchRequest<SoundObject>(entityName: "SoundObject")
        
        // add NSSortDescriptor to the fetch request orderung the results by name
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        self.fetchRequest!.sortDescriptors = [nameSort]
        
        // creates NSFetchedResultsController and assigns its fetchRequest and target moc
        fetchedResultsController = NSFetchedResultsController(fetchRequest: self.fetchRequest!, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        // set delegate so class methods will be called on certain events
        fetchedResultsController.delegate = self
        
        // fetch results, will be accessable in fetchedResultsController
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
        // instead of using static source, the fetchedResultsController is used
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundCellView", for: indexPath) as! SoundCellView
        
        // instead of using static source, the fetchedResultsController is used
        guard let soundObject = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.update(soundObject)
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
    
    // callback if NSFetchedResultsController updates its Rows
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView?.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView?.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView?.moveRow(at: indexPath!, to: newIndexPath!)
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
        let cell = fetchedResultsController.object(at: indexPath)
        let addEditSoundController = AddEditSoundController()
        addEditSoundController.editableSound = cell
        self.navigationController!.pushViewController(addEditSoundController, animated: true)

        self.tableView?.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
}

