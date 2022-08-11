//
//  LRUMemoryCache.swift
//  INSFoundationKit
//
//  Created by Leo wang on 2022/8/11.
//  Copyright © 2022 INSTA360. All rights reserved.
//

import Foundation

fileprivate extension LRUMemoryCache {
    
    class CacheItem<KeyType, ValueType>: NSObject {
        
        var value: ValueType
        
        let key: KeyType
        
        var pre: CacheItem?
        
        var next: CacheItem?
        
        init(value: ValueType, key: KeyType) {
            self.value = value
            self.key = key
        }
    }
}

public class LRUMemoryCache<KeyType: Hashable, ValueType> {
    
    private let capacity: Int
    
    private var totalCount: Int = 0
    
    private let cacheSemaphore: DispatchSemaphore = DispatchSemaphore.init(value: 1)
    
    private var itemCache: [KeyType: CacheItem<KeyType, ValueType>] = [:]
    
    private var head: CacheItem<KeyType, ValueType>?
    
    private var tail: CacheItem<KeyType, ValueType>?
    
    deinit {
        print("LRUMemoryCache deinit", KeyType.self, ValueType.self)
    }
    
    public init(capacity: Int = 100) {
        self.capacity = capacity
    }
    
    /// set
    public func setValue(_ value: ValueType, key: KeyType) {
        cacheSemaphore.wait()
        defer {
            cacheSemaphore.signal()
        }
        // 已存在则更新位置
        if let item = itemCache[key] {
            item.value = value
            deleteItem(item)
            insertItem(item)
            return
        }
        /// 超过最大容量就删除末尾一个
        if totalCount >= capacity{
            totalCount -= 1
            deleteTailItem()
        }
        totalCount += 1
        // 不包含，就插入头节点
        let item = CacheItem(value: value, key: key)
        insertItem(item)
        itemCache.updateValue(item, forKey: key)
    }
    
    /// get
    public func fetchValue(with key: KeyType) -> ValueType? {
        cacheSemaphore.wait()
        defer {
            cacheSemaphore.signal()
        }
        guard let item = itemCache[key] else { return nil }
        // 已存在则更新位置
        deleteItem(item)
        insertItem(item)
        return item.value
    }
    
    /// 有序遍历
    public func forEach(_ body: (KeyType, ValueType) -> Void) {
        cacheSemaphore.wait()
        defer {
            cacheSemaphore.signal()
        }
        var head: CacheItem<KeyType, ValueType>? = self.head
        while let temp = head {
            body(temp.key, temp.value)
            head = head?.next
        }
    }
    
    private func insertItem(_ item: CacheItem<KeyType, ValueType>) {
        item.pre = nil
        item.next = head
        head?.pre = item
        head = item
        if totalCount == 1 {
            tail = item
        }
        itemCache[item.key] = item
    }
    
    private func deleteItem(_ item: CacheItem<KeyType, ValueType>) {
        if item == tail {
            tail = item.pre
        }
        item.pre?.next = item.next
        item.next?.pre = item.pre
        itemCache.removeValue(forKey: item.key)
    }
    
    private func deleteTailItem() {
        guard let tail = tail else {
            return
        }
        deleteItem(tail)
    }
}
