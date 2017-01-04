//
//  FullLibraryDataSource.swift
//  Ookami
//
//  Created by Maka on 2/1/17.
//  Copyright © 2017 Mikunj Varsani. All rights reserved.
//

import UIKit
import OokamiKit
import RealmSwift

//A datasource which displays an entire library of a certain type and status
final class FullLibraryDataSource: LibraryEntryDataSource {
    var delegate: ItemViewControllerDelegate? {
        didSet {
            delegate?.didReloadItems(dataSource: self)
            
            //Check if we have the results and if we don't then show the indicator
            if let results = results,
                results.count == 0,
                fetchedEntries == false {
                delegate?.showActivityIndicator()
            }
        }
    }
    
    //The user id
    let userID: Int
    
    //The type of library
    let type: Media.MediaType
    
    //The status of the library
    let status: LibraryEntry.Status
    
    //Realm tokem
    var token: NotificationToken?
    
    //Realm results
    var results: Results<LibraryEntry>?
    
    //Max amount of time we are allowed to retry
    let maxRetryCount = 3
    
    //Current retry count
    var retryCount = 0
    
    //Bool to indicate whether we have fetched entries or not
    var fetchedEntries = false
    
    /// Create a library data source that fetches a full library for the given `user` and `status`
    ///
    /// - Parameters:
    ///   - userID: The user id
    ///   - type: The type of library to fetch
    ///   - status: The status of the library to fetch
    init(userID: Int, type: Media.MediaType, status: LibraryEntry.Status) {
        self.userID = userID
        self.type = type
        self.status = status
        
        updateResults(with: .updatedAt)
        fetchLibrary()
    }
    
    deinit {
        token?.stop()
    }
    
    /// Fetch the library info
    func fetchLibrary(resetRetry: Bool = false) {
        
        if resetRetry { retryCount = 0 }
        
        var lastFetched: Date = Date(timeIntervalSince1970: 0)
        
        //Get the fetch time if user has it
        if let fetched = LastFetched.get(withId: userID) {
            switch type {
            case .anime:
                lastFetched = fetched.anime
            case .manga:
                lastFetched = fetched.manga
            }
        }
        
        if retryCount <= self.maxRetryCount {
            
            LibraryService().get(userID: userID, type: type, status: status, since: lastFetched) { error in
                
                //If we get an error and we can still retry then do it
                if let _ = error, self.retryCount + 1 <= self.maxRetryCount {
                    self.retryCount += 1
                    self.fetchLibrary()
                    return
                }
                
                //We successfully fetched entries
                self.fetchedEntries = true
                
                //Hide the indicator if we have recieved all the results
                self.delegate?.hideActivityIndicator()
            }
        } else {
            
            //We have reached the retry count. Hide the indicator.
            self.delegate?.hideActivityIndicator()
        }
    }
    
}

//MARK: - LibraryEntryDataSource
extension FullLibraryDataSource {
    
    func items() -> [ItemData] {
        guard let results = results else {
            return []
        }
        
        return Array(results).map { $0.toItemData() }
    }
    
    func didSelectItem(at indexpath: IndexPath) {
        
    }
    
    /// Update the realm results we are storing with a filter
    ///
    /// - Parameter filter: The filter that is to be used
    func updateResults(with filter: LibraryViewController.Filter?) {
        
        //TODO: Add function in LibraryEntry to make this more readable
        results = LibraryEntry.belongsTo(user: userID).filter("media.rawType = %@ AND rawStatus = %@", type.rawValue, status.rawValue).sorted(byProperty: "updatedAt", ascending: false)
        
        token?.stop()
        token = results?.addNotificationBlock { [weak self] changes in
            if let strong = self {
                strong.delegate?.didReloadItems(dataSource: strong)
                
                //Hide the indicator if results were updated
                let count = strong.results?.count ?? 0
                if count > 0 {
                    strong.delegate?.hideActivityIndicator()
                }
            }
        }
    }
    
    func didSet(filter: LibraryViewController.Filter) {
        updateResults(with: filter)
    }
}