//
//  FetchAllLibraryOperation.swift
//  Ookami
//
//  Created by Maka on 12/11/16.
//  Copyright © 2016 Mikunj Varsani. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

//Note: We can make it so FetchAllLibraryOperation recieves a request from a (LibraryEntry.Status) -> PagedKitsuRequest block so that it is not the one to create the request, rather it is left upon the user to provide the neccessary data.
// This is advantageos because we may want to fetch a full library with different filters or includes.

/// Operation to fetch all the the entries in a specific library
/// This will also delete any library entries that were not recieved (if everything succeeds)
public class FetchAllLibraryOperation: AsynchronousOperation {
    
    public typealias FetchCompletionBlock = ([StatusError]) -> Void
    public typealias OnFetchBlock = ([Object]) -> Void
    public typealias StatusError = (LibraryEntry.Status, Error)
    
    var queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 5
        return q
    }()
    
    /// An array containing tuples with indicate whether a status failed, includes the error in the tuple
    var failed: [StatusError] = []
    
    /// A dictionary which keeps track of the statuses and whether we have finished fetching them
    var statuses: [LibraryEntry.Status: Bool] = [:]
    
    /// The endpoint url for fetching library entries
    public let url: String
    
    /// The id of the user to fetch the library for
    public let userID: Int
    
    /// The client to use for executing requests
    public let client: NetworkClientProtocol
    
    /// The completion block
    let fetchCompletion: FetchCompletionBlock
    
    //The fetch callback block which gets called everytime objects are recieved
    let onFetch: OnFetchBlock
    
    /// The type of library being fetched
    let type: Media.MediaType
    
    /// Create a library operation to fetch all of the users library for a given type
    ///
    /// - Parameters:
    ///   - relativeURL: The api url for library get
    ///   - userID: The user id to fetch the library for
    ///   - type: The type of library to fetch
    ///   - client: The network client to execute request on
    ///   - onFetch: The callback which gets called when objects are fetched, and returns both entries and related objects. This will get called multiple times.
    ///   - completion: The completion callback which passes an array of tuples of kind `(LibraryEntry.Status, Error)` which are set when a status failed to fetch
    public init(relativeURL: String, userID: Int, type: Media.MediaType, client: NetworkClientProtocol, onFetch: @escaping OnFetchBlock, completion: @escaping FetchCompletionBlock) {
        self.url = relativeURL
        self.userID = userID
        self.client = client
        self.fetchCompletion = completion
        self.onFetch = onFetch
        self.type = type
    }
    
    override public func main() {
        var operations: [Operation] = []
        
        //Set the initial state of the statuses
        LibraryEntry.Status.all.forEach { statuses[$0] = false }
        
        //Go through each of the statuses and make the operations
        statuses.keys.forEach { status in
            
            //Make the request
            let request = PagedKitsuRequest(relativeURL: url)
            request.filter(key: "user_id", value: userID)
            request.filter(key: "media_type", value: type.toLibraryMediaTypeString())
            request.filter(key: "status", value: status.rawValue)
            request.include("media", "user")
            
            let operation = FetchLibraryOperation(request: request, client: client, onFetch: onFetch, completion: { error in
                
                //Check for any errors
                if error != nil {
                    self.failed.append((status, error!))
                    print("Failed to fetch \(status.rawValue) library: " + (error?.localizedDescription)!)
                }
                
                self.statuses[status] = true
                
                //Check if we have fetched all the statuses
                var allFetched = true
                for fetched in self.statuses.values {
                    if !fetched {
                        allFetched = false
                        break
                    }
                }
 
                //If we have then we finish the operation
                if allFetched {
                    self.fetchCompletion(self.failed)
                    self.completeOperation()
                }
                
            })
            
            operations.append(operation)
        }
        
        //Start the operations
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    override public func cancel() {
        queue.cancelAllOperations()
        super.cancel()
        queue.addOperation {
            self.completeOperation()
        }
    }
}
