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
    private var threadSafeBox: ThreadSafeBox<T>
    private var accessQueue = DispatchQueue.init(label: UUID().uuidString)
    
    public func object() throws -> T? {
        let currentThreadDescription = Thread.current.description
        return try accessQueue.sync(execute: { () -> ThreadSafeBox<T>? in
            if threadSafeBox.lastThreadDescription == currentThreadDescription {
                return threadSafeBox
            } else {
                guard let object = try threadSafeBox.resolvable.resolve() else { return nil }
                threadSafeBox = ThreadSafeBox(object: object)
                return threadSafeBox
            }
        })?._object
    }
    
    public init(object: T) {
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
