//
//  AppDelegate.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 05.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import SwiftySound
import AudioKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window : UIWindow?
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let navigationController = app.windows[0].rootViewController as! UINavigationController
        let addEditSoundController = AddEditSoundController()
        addEditSoundController.state = .AddExternal
        addEditSoundController.externalAudioURL = url
        navigationController.pushViewController(addEditSoundController, animated: true)
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("LaunchOptionsKey")
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let modelName = "SoundsBoard"
        var container: NSPersistentContainer!
        if #available(iOS 13.0, *) {
            container = NSPersistentContainer(name: modelName)
        } else {
            var modelURL = Bundle(for: type(of: self)).url(forResource: modelName, withExtension: "momd")!
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
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
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
