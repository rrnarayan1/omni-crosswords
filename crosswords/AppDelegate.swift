//
//  AppDelegate.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/19/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseAuth
import FontAwesome_swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(title: "Next Clue", action: #selector(handleNextClue(sender:)), input: UIKeyCommand.inputRightArrow, modifierFlags: .shift),
            
            UIKeyCommand(title: "Previous Clue", action: #selector(handlePreviousClue(sender:)), input: UIKeyCommand.inputLeftArrow, modifierFlags: .shift),
            
            UIKeyCommand(title: "Left Cell", action: #selector(handleLeftCell(sender:)), input: UIKeyCommand.inputLeftArrow),
            UIKeyCommand(title: "Right Cell", action: #selector(handleRightCell(sender:)), input: UIKeyCommand.inputRightArrow),
            UIKeyCommand(title: "Up Cell", action: #selector(handleUpCell(sender:)), input: UIKeyCommand.inputUpArrow),
            UIKeyCommand(title: "Down Cell", action: #selector(handleDownCell(sender:)), input: UIKeyCommand.inputDownArrow)
        ]
    }
    
    @objc func handleNextClue(sender: UIKeyCommand) {
        NotificationCenter.default.post(name: .init("nextClue"), object: "")
    }
    
    @objc func handlePreviousClue(sender: UIKeyCommand) {
        NotificationCenter.default.post(name: .init("previousClue"), object: "")
    }
    
    @objc func handleRightCell(sender: UIKeyCommand) {
        NotificationCenter.default.post(name: .init("rightCell"), object: "")
    }
    
    @objc func handleLeftCell(sender: UIKeyCommand) {
        NotificationCenter.default.post(name: .init("leftCell"), object: "")
    }
    
    @objc func handleUpCell(sender: UIKeyCommand) {
        NotificationCenter.default.post(name: .init("upCell"), object: "")
    }
    
    @objc func handleDownCell(sender: UIKeyCommand) {
        NotificationCenter.default.post(name: .init("downCell"), object: "")
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "crosswords")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                print("Could not save core data :(")
            }
        }
    }
}

