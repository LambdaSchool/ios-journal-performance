//
//  Cache.swift
//  JournalCoreData
//
//  Created by Karen Rodriguez on 4/14/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

class Cache<Key: Hashable, Value> {
    
    func cache(value: Value, for key: Key) {
        cache[key] = value
    }
    
    func value(for key: Key) -> Value? {
        return cache[key]
    }
    
    private var cache = [Key : Value]()
}
