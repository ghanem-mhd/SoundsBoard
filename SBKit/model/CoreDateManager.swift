//
//  CoreDateManager.swift
//  SBKit
//
//  Created by Mohammad Ghanem on 11.04.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import CoreData


public class CoreDataManager {
    
    public static let shared = CoreDataManager()
    
    let identifier: String  = "com.example.SBKit"       //Your framework bundle ID
    let modelName: String       = "SoundsBoard"                      //Model name
    
    
    public lazy var persistentContainer: NSPersistentContainer = {
        var container: NSPersistentContainer!
        let messageKitBundle = Bundle(identifier: self.identifier)
        var modelURL = messageKitBundle!.url(forResource: self.modelName, withExtension: "momd")!
        let versionInfoURL = modelURL.appendingPathComponent("VersionInfo.plist")
        if let versionInfoNSDictionary = NSDictionary(contentsOf: versionInfoURL),
            let version = versionInfoNSDictionary.object(forKey: "NSManagedObjectModel_CurrentVersionName") as? String {
            modelURL.appendPathComponent("\(version).mom")
            let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
            container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel!)
        } else {
            //fall back solution; runs fine despite "Failed to load optimized model" warning
            container = NSPersistentContainer(name: modelName)
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    public func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
