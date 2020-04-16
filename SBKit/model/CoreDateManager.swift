//
//  CoreDateManager.swift
//  SBKit
//
//  Created by Mohammad Ghanem on 11.04.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import CoreData


class PersistentContainer: NSPersistentContainer {
    internal override class func defaultDirectoryURL() -> URL {
        var url = super.defaultDirectoryURL()
        if let newURL =
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.SoundsBoard") {
            url = newURL
        }
        return url
    }
}


public class CoreDataManager {
    
    public let MAXIMUM_FAVORITE_SOUNDS = 9
    
    let modelName: String       = "SoundsBoard"
    let appGroupID: String      = "group.SoundsBoard"
    
    public static let shared = CoreDataManager()
    public var errorHandler: (Error) -> Void = {_ in }
    
    public lazy var persistentContainer: NSPersistentContainer = {
        
        let container = PersistentContainer(name: modelName)
        var persistentStoreDescriptions: NSPersistentStoreDescription
        
        let storeUrl =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!.appendingPathComponent("\(modelName).sqlite")
        
        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = storeUrl
        
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url:  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!.appendingPathComponent("\(modelName).sqlite"))]
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    //#2
    public lazy var managedContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    //#3
    // Optional
    public lazy var backgroundContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
    
    //#4
    public func performForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.managedContext.perform {
            block(self.managedContext)
        }
    }
    
    //#5
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.persistentContainer.performBackgroundTask(block)
    }
    
    //#6
    public func saveContext () {
        guard managedContext.hasChanges else { return }
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
    
    public func createDummy(){
        let moc = managedContext
        if let soundEntity = NSEntityDescription.entity(forEntityName: "SoundObject", in: moc){
            let soundObject = NSManagedObject(entity: soundEntity, insertInto: moc)
            soundObject.setValue(randomString(length: 5), forKeyPath: "name")
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
                moc.rollback()
            }
        }
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    private func getFavoritesCount() -> Int{
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: "SoundObject")
        fetchRequest.predicate = NSPredicate(format: "isFavorite == %@", NSNumber(value: true))
        do {
            let count = try managedContext.count(for: fetchRequest)
            return count
        } catch let error as NSError {
            print(error)
            return -1
        }
    }
    
    public func maxFavoriteReached() -> Bool{
        let count = getFavoritesCount()
        if count == -1{
            return true
        }
        if count >= MAXIMUM_FAVORITE_SOUNDS{
            return true
        }
        return false
    }
}
