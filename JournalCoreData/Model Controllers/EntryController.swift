//
//  EntryController.swift
//  JournalCoreData
//
//  Created by Spencer Curtis on 8/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class EntryController {
    // MARK: - Properties
    
    typealias Completion = ((Error?) -> Void)
    
    private let baseURL = URL(string: "https://journal-performance2.firebaseio.com/")!
    
    private var entryRepsFromServer = Cache<String, EntryRepresentation>()
    private var coreDataEntries = Cache<String, Entry>()
    
    private var coreDataOps = [Operation]()
    private var serverOps = [Operation]()
    private var coreDataQueue = OperationQueue()
    private var serverQueue = OperationQueue()
    
    // MARK: - Public API
        
    func createEntry(with title: String, bodyText: String, mood: String) {
        let entry = Entry(title: title, bodyText: bodyText, mood: mood)
        
        put(entry: entry)
        
        saveToPersistentStore()
    }
    
    func update(entry: Entry, title: String, bodyText: String, mood: String) {
        entry.title = title
        entry.bodyText = bodyText
        entry.timestamp = Date()
        entry.mood = mood
        
        put(entry: entry)
        
        saveToPersistentStore()
    }
    
    func delete(entry: Entry) {
        CoreDataStack.shared.mainContext.delete(entry)
        deleteEntryFromServer(entry: entry)
        saveToPersistentStore()
    }
    
    func syncWithServer(completion: @escaping (Error?) -> Void = { _ in }) {
        let context = CoreDataStack.shared.container.newBackgroundContext()
        
        for op in serverOps {
            op.cancel()
        }
        for op in coreDataOps {
            op.cancel()
        }
        
        let fetchFromCoreDataOp = BlockOperation {
            guard let entries = self.fetchAllEntriesFromPersistentStore(in: context)
                else { return }
            for entry in entries {
                guard let id = entry.identifier else { continue }
                self.coreDataEntries[id] = entry
            }
        }
        coreDataOps.append(fetchFromCoreDataOp)
        
        let fetchFromServerOp = BlockOperation {
            self.fetchEntriesFromServer { entryReps, error in
                if let error = error {
                    completion(error)
                    return
                }
                guard let serverReps = entryReps else { return }
                self.handleEntriesFromServer(
                    serverReps,
                    in: context,
                    after: fetchFromCoreDataOp,
                    completion: completion)
            }
        }
        serverOps.append(fetchFromServerOp)
        
        serverQueue.addOperation(fetchFromServerOp)
        coreDataQueue.addOperation(fetchFromCoreDataOp)
    }
    
    // MARK: - Private Sync Methods
    
    private func handleEntriesFromServer(
        _ serverReps: [EntryRepresentation],
        in context: NSManagedObjectContext,
        after fetchFromCoreDataOp: Operation,
        completion: @escaping (Error?) -> Void)
    {
        let completionOp = BlockOperation {
            var caughtError: Error? = nil
            
            if context.hasChanges { context.performAndWait {
                do { try context.save() }
                catch { caughtError = error }}
                
                self.saveToPersistentStore()
            }
            
            completion(caughtError)
        }
        
        for serverRep in serverReps {
            guard let id = serverRep.identifier else { continue }
            self.entryRepsFromServer[id] = serverRep
            
            let cdUpdateOp = BlockOperation {
                context.performAndWait {
                    if let coreDataEntry = self.coreDataEntries[id] {
                        coreDataEntry.update(with: serverRep)
                    } else {
                        self.coreDataEntries[id] = Entry(
                            entryRepresentation: serverRep,
                            context: context)
                    }
                }
            }
            
            cdUpdateOp.addDependency(fetchFromCoreDataOp)
            completionOp.addDependency(cdUpdateOp)
            
            self.coreDataOps.append(cdUpdateOp)
            self.coreDataQueue.addOperation(cdUpdateOp)
        }
        
        let sendNewOpsToServer = BlockOperation {
            for (id, entry) in self.coreDataEntries {
                if self.entryRepsFromServer[id] == nil {
                    self.put(entry: entry)
                }
            }
        }
        sendNewOpsToServer.addDependency(fetchFromCoreDataOp)
        
        self.serverOps.append(sendNewOpsToServer)
        self.serverQueue.addOperation(sendNewOpsToServer)
        
        self.coreDataQueue.addOperation(completionOp)
        
    }
    
    private func put(
        entry: Entry,
        completion: @escaping ((Error?) -> Void) = { _ in })
    {
        let identifier = entry.identifier ?? UUID().uuidString
        let requestURL = baseURL.appendingPathComponent(identifier).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        do {
            request.httpBody = try JSONEncoder().encode(entry)
        } catch {
            NSLog("Error encoding Entry: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error PUTting Entry to server: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    private func deleteEntryFromServer(entry: Entry, completion: @escaping ((Error?) -> Void) = { _ in }) {
        guard let identifier = entry.identifier else {
            NSLog("Entry identifier is nil")
            completion(NSError())
            return
        }
        
        let requestURL = baseURL
            .appendingPathComponent(identifier)
            .appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error deleting entry from server: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    private func fetchEntriesFromServer(
        completion: @escaping (([EntryRepresentation]?, Error?) -> Void) = { _,_ in })
    {
        let requestURL = baseURL.appendingPathExtension("json")
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching entries from server: \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(nil, NSError())
                return
            }

            do {
                let entryReps = try JSONDecoder().decode([String: EntryRepresentation].self, from: data).map({$0.value})
                
                completion(entryReps, nil)
            } catch {
                NSLog("Error decoding JSON data: \(error)")
                completion(nil, error)
                return
            }
        }.resume()
    }
    
    // MARK: - Private CoreData Methods
    
    private func fetchAllEntriesFromPersistentStore(
        in context: NSManagedObjectContext,
        completion: (Error?) -> Void = { _ in }
    ) -> [Entry]? {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        var entries: [Entry]? = nil
        context.performAndWait {
            do {
                entries = try context.fetch(fetchRequest)
            } catch {
                completion(error)
            }
        }
        return entries
    }
    
    private func saveToPersistentStore() {
        do {
            try CoreDataStack.shared.mainContext.save()
        } catch {
            NSLog("Error saving managed object context: \(error)")
        }
    }
}
