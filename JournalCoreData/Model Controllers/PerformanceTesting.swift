//
//  PerformanceTesting.swift
//  JournalCoreData
//
//  Created by Gladymir Philippe on 9/20/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

let loremIpsum = "nada"

extension String {
    var words: [String] {
        return components(separatedBy: .whitespacesAndNewlines)
    }
    
    var randomWord: String {
        return words.randomItem()
    }
}

extension Array {
    func randomItem() -> Element {
        let index = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}

extension Date {
    static func randomDateBefore(date: Date) -> Date {
        let limit = date.timeIntervalSinceReferenceDate
        let randomTime = TimeInterval(arc4random_uniform(UInt32(limit)))
        return Date(timeIntervalSinceReferenceDate: randomTime)
    }
}

extension EntryController {
    
    func createDummyEntries(completion: @escaping ((Error?) -> Void) = { _ in }) {
        let entries = dummyEntries(count: 10000)
        
        let requestURL = baseURL.appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        do {
            request.httpBody = try JSONEncoder().encode(entries)
        } catch {
            NSLog("Error uploading dummy entries: \(error)")
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error PUTting dumming entries to server: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    func dummyEntries(count: Int) -> [String :  EntryRepresentation] {
        
        let moods = Mood.allCases
        
        let now = Date()
        var result = [String : EntryRepresentation]()
        for _ in 0..<count {
            let title = loremIpsum.randomWord + " " + loremIpsum.randomWord
            let timestamp = Date.randomDateBefore(date: now)
            let id = UUID().uuidString
            let entry = EntryRepresentation(title: title, bodyText: loremIpsum, mood: moods.randomItem().rawValue, timestamp: timestamp, identifier: id)
            result[id] = entry
        }
        return result
    }
    
}

