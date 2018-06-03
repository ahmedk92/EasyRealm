//
//  TestThreadSafe.swift
//  EasyRealm_Example
//
//  Created by admin on 5/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import RealmSwift
import EasyRealm

class TestThreadSafe: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
    
    override func tearDown() {
        super.tearDown()
        let realm = try! Realm()
        try! realm.write { realm.deleteAll() }
    }
    
    func testResolvable() {
        let pokeball = Pokeball.create()
        try! pokeball.er.edit {
            $0.branding = "OK"
        }
        try! pokeball.er.save()
        
        let threadSafePokeballResolvable = try! Pokeball.er.all().first!.er.threadSafeResolvable
        DispatchQueue(label: UUID().uuidString).async {
            XCTAssert(try! threadSafePokeballResolvable.resolve()!.branding == "OK")
        }
        
        sleep(3)
    }
    
    func testWrapper() {
        let pokeball = Pokeball.create()
        try! pokeball.er.edit {
            $0.branding = "OK"
        }
        try! pokeball.er.save()
        
        let threadSafePokeball = try! Pokeball.er.all().first!.er.threadSafeWrapper
        
        XCTAssert(try! threadSafePokeball.object()!.branding == "OK")
        
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssert(try! threadSafePokeball.object()!.branding == "OK")
        }
        
        sleep(5)
        
        XCTAssert(try! threadSafePokeball.object()!.branding == "OK")
        
    }
}

