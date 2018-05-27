//
//  ThreadSafe.swift
//  EasyRealm
//
//  Created by admin on 5/19/18.
//

import RealmSwift

public struct ThreadSafeResolvable<T: Object> {
    typealias Generator = () throws -> T?
    private let generator: Generator
    
    public func resolve() throws -> T? {
        return try generator()
    }
    
    init(generator: @escaping Generator) {
        self.generator = generator
    }
}

public class ThreadSafeWrapper<T: Object> {
    private var threadSafe: ThreadSafeBox<T>
    private var accessQueue = DispatchQueue.init(label: UUID().uuidString)
    
    public func object() throws -> T? {
        return try accessQueue.sync(execute: { () -> T? in
            if threadSafe.lastThreadDescription == Thread.current.description {
                return threadSafe._object
            } else {
                guard let object = try threadSafe.resolvable.resolve() else { return nil }
                threadSafe = ThreadSafeBox(object: object)
                return threadSafe._object
            }
        })
    }
    
    public init(object: T) {
        threadSafe = ThreadSafeBox(object: object)
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
            return ThreadSafeResolvable(generator: {
                let realm = try Realm()
                return realm.resolve(reference)
            })
        }(ThreadSafeReference(to: self.base))
    }
    
    public var threadSafeWrapper: ThreadSafeWrapper<T> {
        return ThreadSafeWrapper.init(object: self.base)
    }
}
