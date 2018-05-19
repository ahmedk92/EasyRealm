//
//  ThreadSafe.swift
//  EasyRealm
//
//  Created by admin on 5/19/18.
//

import RealmSwift

struct Resolvable<T: Object> {
    typealias Generator = () throws -> T?
    private let generator: Generator
    
    func resolve() throws -> T? {
        return try generator()
    }
    
    init(generator: @escaping Generator) {
        self.generator = generator
    }
}

public class ThreadSafeWrapper<T: Object> {
    private var resolvable: Resolvable<T>
    private var lastThreadDescription: String
    private var _object: T
    public func object() throws -> T? {
        if lastThreadDescription == Thread.current.description {
            return _object
        } else {
            guard let object = try resolvable.resolve() else { return nil }
            reset(withObject: object)
            return _object
        }
    }
    
    private func reset(withObject object: T) {
        _object = object
        resolvable = object.er.resolvable
        lastThreadDescription = Thread.current.description
    }
    
    public init(object: T) {
        _object = object
        resolvable = object.er.resolvable
        lastThreadDescription = Thread.current.description
    }
}

extension EasyRealm where T: Object {
    var resolvable: Resolvable<T> {
        return { (reference) in
            return Resolvable(generator: {
                let realm = try Realm()
                return realm.resolve(reference)
            })
        }(ThreadSafeReference(to: self.base))
    }
    
    public var threadSafeWrapper: ThreadSafeWrapper<T> {
        return ThreadSafeWrapper.init(object: self.base)
    }
}
