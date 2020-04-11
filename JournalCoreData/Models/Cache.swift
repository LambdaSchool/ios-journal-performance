//
//  Cache.swift
//  JournalCoreData
//
//  Created by Jessie Ann Griffin on 4/10/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class Cache<Key: Hashable, Value> {
    
    func cache(value: Value, for key: Key) {
        cache[key] = value
    }
    
    func value(for key: Key) -> Value? {
        return cache[key]
    }
    
    private var cache = [Key : Value]()
}
