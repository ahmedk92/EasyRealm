//
//  ThreadSafe.swift
//  EasyRealm
//
//  Created by admin on 5/19/18.
//

import RealmSwift

public struct ThreadSafeResolvable<T: Object> {
    typealias Generator = (Realm) throws -> T?
    private let generator: Generator
    
    public func resolve() throws -> T? {
        return try generator(try Realm())
    }
    
    init(generator: @escaping Generator) {
        self.generator = generator
    }
}

public class ThreadSafeWrapper<T: Object> {
    private var threadSafeBox: ThreadSafeBox<T>
    private var lock = NSObject()
    
    public func object() throws -> T? {
        objc_sync_enter(lock)
        defer {
            objc_sync_exit(lock)
        }
        if threadSafeBox.lastThreadDescription == Thread.current.description {
            return threadSafeBox._object
        } else {
            guard let object = try threadSafeBox.resolvable.resolve() else { return nil }
            threadSafeBox = ThreadSafeBox(object: object)
            return threadSafeBox._object
        }
    }
    
    public init(object: T) {
        objc_sync_enter(lock)
        defer {
            objc_sync_exit(lock)
        }
        threadSafeBox = ThreadSafeBox(object: object)
    }
}

fileprivate struct ThreadSafeBox<T: Object> {
    fileprivate var resolvable: ThreadSafeResolvable<T>
    fileprivate var lastThreadDescription: String
    fileprivate var _object: T
    
    fileprivate init(object: T) {
        _object = object
        resolvable = object.er.threadSafeResolvable
        lastThreadDescription = Thread.current.description
    }
}

extension EasyRealm where T: Object {
    public var threadSafeResolvable: ThreadSafeResolvable<T> {
        return { (reference) in
            return ThreadSafeResolvable(generator: { (realm) in
                return realm.resolve(reference)
            })
        }(ThreadSafeReference(to: self.base))
    }
    
    public var threadSafeWrapper: ThreadSafeWrapper<T> {
        return ThreadSafeWrapper.init(object: self.base)
    }
}
