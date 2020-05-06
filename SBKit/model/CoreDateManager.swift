//
//  CoreDateManager.swift
//  SBKit
//
//  Created by Mohammad Ghanem on 11.04.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class PersistentContainer: NSPersistentContainer {
    internal override class func defaultDirectoryURL() -> URL {
        var url = super.defaultDirectoryURL()
        if let newURL =
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: Constants.appGroupID) {
            url = newURL
        }
        return url
    }
}


public class CoreDataManager {
    
    private static let mangedObjectName = "SoundObject"
    
    public static let shared = CoreDataManager()
    public var errorHandler: (Error) -> Void = {_ in }
    
    public lazy var persistentContainer: NSPersistentContainer = {
        
        let container = PersistentContainer(name: Constants.modelName)
        var persistentStoreDescriptions: NSPersistentStoreDescription
        
        let storeUrl =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)!.appendingPathComponent("\(Constants.modelName).sqlite")
        
        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = storeUrl
        
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url:  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)!.appendingPathComponent("\(Constants.modelName).sqlite"))]
        
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
    
    public func getSoundsControllerFetchReqest() -> NSFetchRequest<SoundObject>{
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: CoreDataManager.mangedObjectName)
        let favoriteSort = NSSortDescriptor(key: "isFavorite", ascending: false)
        let sortId = NSSortDescriptor(key: "sortId", ascending: true)
        fetchRequest.sortDescriptors = [favoriteSort, sortId]
        return fetchRequest
    }
    
    public func getMoreControllerFetchReqest() -> NSFetchRequest<SoundObject>{
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: CoreDataManager.mangedObjectName)
        let sortId = NSSortDescriptor(key: "sortId", ascending: true)
        fetchRequest.sortDescriptors = [sortId]
        return fetchRequest
    }
    
    public func getWidgetFetchReqest() -> NSFetchRequest<SoundObject>{
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: CoreDataManager.mangedObjectName)
        let sortId = NSSortDescriptor(key: "sortId", ascending: true)
        fetchRequest.sortDescriptors = [sortId]
        fetchRequest.predicate = NSPredicate(format: "isFavorite == %@", NSNumber(value: true))
        return fetchRequest
    }
    
    public func create(numberOfSound:Int){
        for n in 1...numberOfSound {
            saveNewSound("\(n)th", 0.5, nil,"")
        }
    }
    
    public func test() -> [SoundObject]?{
        do {
            let sounds = try managedContext.fetch(getMoreControllerFetchReqest())
            return sounds
        } catch let error as NSError {
            print(error)
            return nil
        }
    }
    
    public func deleteAll(){
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: CoreDataManager.mangedObjectName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try managedContext.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
    
    public func saveNewSound(_ soundName:String, _ volume: Float, _ soundImage:UIImage?, _ soundFileName:String)-> Bool {
        guard let soundEntity = NSEntityDescription.entity(forEntityName: CoreDataManager.mangedObjectName, in: managedContext) else{
            return false
        }
        let soundObject = NSManagedObject(entity: soundEntity, insertInto: managedContext)
        soundObject.setValue(soundName, forKeyPath: "name")
        soundObject.setValue(volume, forKeyPath: "volume")
        soundObject.setValue(soundFileName, forKeyPath: "fileName")
        if let image = soundImage{
            soundObject.setValue(image.pngData(), forKeyPath: "image")
        }
        let soundsCount = getSoundsCount()
        if soundsCount == -1{
            return false
        }else{
            soundObject.setValue(soundsCount, forKeyPath: "sortId")
        }
        do {
            try managedContext.save()
            return true
        } catch let error as NSError {
            print(error)
            managedContext.rollback()
            return false
        }
    }
    
    public func getSoundsCount() -> Int{
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: CoreDataManager.mangedObjectName)
        do {
            let count = try managedContext.count(for: fetchRequest)
            return count
        } catch let error as NSError {
            print(error)
            return -1
        }
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    private func getFavoritesCount() -> Int{
        let fetchRequest = NSFetchRequest<SoundObject>(entityName: CoreDataManager.mangedObjectName)
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
        if count >= Constants.maximumFavoriteSounds{
            return true
        }
        return false
    }
}
