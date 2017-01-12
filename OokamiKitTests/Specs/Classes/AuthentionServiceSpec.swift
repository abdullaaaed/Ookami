//
//  AuthenticationServiceSpec.swift
//  Ookami
//
//  Created by Maka on 23/11/16.
//  Copyright © 2016 Mikunj Varsani. All rights reserved.
//

import Quick
import Nimble
@testable import OokamiKit
@testable import Heimdallr
import Result
import RealmSwift

private class StubRequestHeimdallr: Heimdallr {
    
    var stubError: NSError? = nil
    var token: Bool = false
    
    override public var hasAccessToken: Bool {
        return token
    }
    
    init(stubError: NSError? = nil) {
        super.init(tokenURL: URL(string: "http://kitsu.io")!)
        self.stubError = stubError
    }
    
    override func clearAccessToken() {
        token = false
    }
    
    override func requestAccessToken(username: String, password: String, completion: @escaping (Result<Void, NSError>) -> ()) {
        if stubError == nil {
            token = true
            completion(.success())
        } else {
            completion(.failure(stubError!))
        }
    }
}

private class StubAuthenticationService: AuthenticationService {
    
    override func updateInfo(completion: @escaping (Error?) -> Void) {
        currentUser.userID = 1
        completion(nil)
    }
    
}

class AuthenticationServiceSpec: QuickSpec {
    override func spec() {
        describe("AuthenticationService") {
            var currentUser: CurrentUser!
            
            beforeEach {
                currentUser = CurrentUser(heimdallr: StubRequestHeimdallr(), userIDKey: "auth-spec-key")
            }
            
            afterEach {
                currentUser.userID = nil
            }
            
            context("Updating user info") {
                class StubUserService: UserService {
                    let e: Error?
                    init(error: Error? = nil) {
                        self.e = error
                        super.init()
                    }
                    override func getSelf(_ completion: @escaping UserService.UserCompletion) {
                        guard e == nil else {
                            completion(nil, e)
                            return
                        }
                        
                        let u = User()
                        u.id = 1
                        u.name = "test"
                        completion(u, nil)
                    }
                }
                
                class StubLibraryService: LibraryService {
                    
                    override func getAll(userID: Int, type: Media.MediaType, since: Date = Date(timeIntervalSince1970: 0), completion: @escaping ([(LibraryEntry.Status, Error)]) -> Void) -> Results<LibraryEntry> {
                        completion([])
                        return LibraryEntry.all()
                    }
                    
                }
                
                it("should not pass error if user is found") {
                    let a = AuthenticationService(currentUser: currentUser)
                    a.userService = StubUserService()
                    a.libraryService = StubLibraryService()
                    waitUntil { done in
                        a.updateInfo { error in
                            expect(error).to(beNil())
                            expect(currentUser.userID).to(equal(1))
                            done()
                        }
                    }
                }
                
                it("should pass error if no user is found") {
                    let a = AuthenticationService(currentUser: currentUser)
                    let e = NetworkClientError.error("generic error")
                    a.userService = StubUserService(error: e)
                    a.libraryService = StubLibraryService()
                    waitUntil { done in
                        a.updateInfo { error in
                            expect(error).toNot(beNil())
                            expect(error).to(matchError(e))
                            done()
                        }
                    }
                }
            }
            
            context("Authentication") {
                it("should return no error if successful") {
                    let a = StubAuthenticationService(currentUser: currentUser)
                    waitUntil { done in
                        a.authenticate(usernameOrEmail: "test", password: "hi") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }
                
                it("should store the user id if successful") {
                    let a = StubAuthenticationService(currentUser: currentUser)
                    a.authenticate(usernameOrEmail: "test", password: "hi") { _ in
                    }
                    expect(currentUser.userID).toEventually(equal(1))
                    expect(currentUser.isLoggedIn()).toEventually(beTrue())
                }
                
                it("should return error if something went wrong") {
                    let nsError: NSError = NSError(domain: "hi", code: 1, userInfo: nil)
                    let cUser = CurrentUser(heimdallr: StubRequestHeimdallr(stubError: nsError), userIDKey: "auth-spec-key")
                    let a = StubAuthenticationService(currentUser: cUser)
                    waitUntil { done in
                        a.authenticate(usernameOrEmail: "test", password: "hi") { error in
                            expect(error).to(matchError(nsError))
                            done()
                        }
                    }
                }
            }
            
        }
    }
}
