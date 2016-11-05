//
//  LibraryEntrySpec.swift
//  Ookami
//
//  Created by Maka on 5/11/16.
//  Copyright © 2016 Mikunj Varsani. All rights reserved.
//

import Quick
import Nimble
@testable import OokamiKit
import SwiftyJSON
import RealmSwift

class LibraryEntrySpec: QuickSpec {
    override func spec() {
        describe("Anime") {
            
            let entryJSON = TestHelper.loadJSON(fromFile: "entry-anime-jigglyslime")!
            var testRealm: Realm!
            
            beforeEach {
                testRealm = RealmProvider.realm()
            }
            
            afterEach {
                try! testRealm.write {
                    testRealm.deleteAll()
                }
            }
            
            context("Fetching & Modifying") {
                it("should be able to fetch a valid entry from the database") {
                    let e = LibraryEntry.parse(json: entryJSON)!
                    try! testRealm.write {
                        testRealm.add(e, update: true)
                    }
                    
                    let another = LibraryEntry.get(withId: e.id)
                    expect(another).toNot(beNil())
                    expect(another?.rawStatus).to(equal(e.rawStatus))
                }
                
                it("should be able to fetch multiple entries from the database") {
                    var ids: [Int] = []
                    TestHelper.create(object: LibraryEntry.self, inRealm: testRealm, amount: 3) { (index, entry) in
                        entry.id = index
                        ids.append(index)
                    }
                    
                    let entry = LibraryEntry.get(withIds: ids)
                    expect(entry.count).to(equal(3))
                }
                
                
                it("should return a nil user if no id is found") {
                    let another = LibraryEntry.get(withId: 1)
                    expect(another).to(beNil())
                }
                
                it("should correctly change the status") {
                    let e = LibraryEntry()
                    expect(e.status).to(beNil())
                    expect(e.rawStatus).to(equal(""))
                    
                    e.status = .current
                    expect(e.status).to(equal(LibraryEntryStatus.current))
                    expect(e.rawStatus).to(equal("current"))
                }
                
                it("should correctly return user") {
                    let e = LibraryEntry()
                    
                    //Defaults to no user
                    expect(e.user).to(beNil())
                    
                    //Set the id
                    e.userId = 1
                    expect(e.user).to(beNil())
                    
                    //Add the user
                    TestHelper.create(object: User.self, inRealm: testRealm, amount: 1) { (index, user) in
                        user.id = 1
                        user.name = "bob"
                    }
                    expect(e.user).toNot(beNil())
                    expect(e.user?.name).to(equal("bob"))
                }
                
                it("should correctly return media and retain only 1 copy") {
                    let media = [Media(value: [1, 0, "hi"]), Media(value: [1, 1, "hello"])]
                    TestHelper.create(object: LibraryEntry.self, inRealm: testRealm, amount: 2) { (index, entry) in
                        entry.id = 1
                        entry.media = media[index]
                    }
                    
                    let entry = LibraryEntry.get(withId: 1)
                    expect(entry).toNot(beNil())
                    expect(entry?.media?.id).to(equal(1))
                    
                    //Check to see that only 1 copy has been made
                    expect(testRealm.objects(Media.self)).to(haveCount(1))
                }
            }
            
            context("Parsing") {
                it("should parse an entry JSON correctly") {
                    let e = LibraryEntry.parse(json: entryJSON)
                    expect(e).toNot(beNil())
                    
                    let entry = e!
                    expect(entry.id).to(equal(340253))
                    expect(entry.rawStatus).to(equal("current"))
                    expect(entry.status).to(equal(LibraryEntryStatus.current))
                    expect(entry.progress).to(equal(131))
                    expect(entry.reconsuming).to(equal(true))
                    expect(entry.reconsumeCount).to(equal(0))
                    expect(entry.notes).to(equal(""))
                    expect(entry.isPrivate).to(equal(true))
                    expect(entry.rating).to(equal(5.0))
                    
                    let d = DateFormatter()
                    d.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SSSZ"
                    let updatedAt = d.date(from: "2016-08-15T11:01:29.181Z")
                    expect(entry.updatedAt).to(equal(updatedAt))
                    
                    expect(entry.userId).to(equal(2875))
                    expect(entry.media).toNot(beNil())
                    expect(entry.media?.id).to(equal(6448))
                    expect(entry.media?.type).to(equal("anime"))
                    
                }
                
                it("should not parse a bad JSON") {
                    let j = JSON("bad JSON")
                    let entry = LibraryEntry.parse(json: j)
                    expect(entry).to(beNil())
                }
            }
        }
    }

}