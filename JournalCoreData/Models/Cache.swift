//
//  Cache.swift
//  JournalCoreData
//
//  Created by Jon Bash on 2019-12-10.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

class Cache<Key: Hashable, Value> {
    private var _cache = [Key: Value]()
    private var queue = DispatchQueue(label: "com.jonbash.Journal-Performance.Cache<\(Key.self), \(Value.self)>")
    
    subscript(_ key: Key) -> Value? {
        get { queue.sync { return self._cache[key] } }
        set { queue.async { self._cache[key] = newValue } }
    }
    
    func clear() {
        queue.async { self._cache.removeAll() }
    }
}
