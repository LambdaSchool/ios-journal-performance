//
//  CoreDataStack.swift
//  JournalCoreData
//
//  Created by Spencer Curtis on 8/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
	static let shared = CoreDataStack()
	private init() {}

	/// A generic function to save any context we want (main or background)
	func save(context: NSManagedObjectContext) throws {
		//Placeholder in case something doesn't work
		var error: Error?

		context.performAndWait {
			do {
				try context.save()
			} catch let saveError {
				NSLog("error saving moc: \(saveError)")
				error = saveError
			}
		}
		if let error = error {
			throw error
		}
	}

	/// Access to the Persistent Container
	lazy var container: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "JournalCoreData")
		container.loadPersistentStores(completionHandler: { (_, error) in
			if let error = error {
				fatalError("Failed to load persistent store: \(error)")
			}
		})
		return container
	}()

	var mainContext: NSManagedObjectContext {
		return container.viewContext
	}
}

