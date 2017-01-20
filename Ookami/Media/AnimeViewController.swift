//
//  AnimeViewController.swift
//  Ookami
//
//  Created by Maka on 13/1/17.
//  Copyright © 2017 Mikunj Varsani. All rights reserved.
//

import UIKit
import OokamiKit
import RealmSwift
import SKPhotoBrowser

//TODO: Add more sections (characters, franchise)

//A view controller to display anime
class AnimeViewController: MediaViewController {
    
    fileprivate var anime: Anime
    
    /// Create an `AnimeViewController`
    ///
    /// - Parameter anime: The anime to display
    init(anime: Anime) {
        self.anime = anime
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Use init(anime:) instead")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the header data
        mediaHeader.data = headerData()
        mediaHeader.delegate = self
        
        //Update the anime
        AnimeService().get(id: anime.id) { _, _ in self.reloadData() }
        
        //Reload the data
        reloadData()
    }
    
    override func sectionData() -> [MediaViewControllerSection] {
        let sections: [MediaViewControllerSection?] = [titleSection(), infoSection(), synopsisSection()]
        return sections.flatMap { $0 }
    }
    
    override func barTitle() -> String {
        return anime.canonicalTitle
    }
    
}

//MARK:- Titles section
extension AnimeViewController {
    fileprivate func titleSection() -> MediaViewControllerSection? {
        return MediaViewControllerHelper.getTitleSection(for: anime.titles)
    }
    
}

//MARK:- Info section
extension AnimeViewController {
    
    fileprivate func infoSection() -> MediaViewControllerSection {
        let info = getInfo()
        return MediaViewControllerHelper.getSectionWithMediaInfoCell(title: "Information", info: info)
    }
    
    fileprivate func getInfo() -> [(title: String, value: String)] {
        var info: [(String, String)] = []
        
        info.append(("Type", anime.subtypeRaw.uppercased()))
        
        let status = anime.isAiring() ? "Airing" : "Finished Airing"
        info.append(("Status", status))
        
        let airingTitle = anime.isAiring() ? "Airing": "Aired"
        let airingText = MediaViewControllerHelper.dateRangeText(start: anime.startDate, end: anime.endDate)
        info.append((airingTitle, airingText))
        
        let episodes = anime.episodeCount > 0 ? "\(anime.episodeCount)" : "?"
        info.append(("Episodes", episodes))
        
        let duration = anime.episodeLength > 0 ? "\(anime.episodeLength)" : "?"
        info.append(("Duration", "\(duration) minutes"))
        
        if !anime.ageRating.isEmpty {
            let prefix = anime.ageRating
            let suffix = anime.ageRatingGuide.isEmpty ? "" : " - \(anime.ageRatingGuide)"
            let rating = prefix.appending(suffix)
            info.append(("Rating", rating))
        }
        
        if anime.genres.count > 0 {
            let genres = anime.genres.map { $0.name }.filter { !$0.isEmpty }
            info.append(("Genres", genres.joined(separator: ", ")))
        }
        
        return info
    }
}

//MARK:- Synopsis Section
extension AnimeViewController {
    fileprivate func synopsisSection() -> MediaViewControllerSection {
        return MediaViewControllerHelper.getSynopsisSection(synopsis: anime.synopsis)
    }
}

//MARK:- Header
extension AnimeViewController {
    
    func getEntry() -> LibraryEntry? {
        return UserHelper.entry(forMedia: .anime, id: anime.id)
    }
    
    func headerData() -> MediaTableHeaderViewData {
        var data = MediaTableHeaderViewData()
        data.title = anime.canonicalTitle
        data.details = ""
        data.airing = ""
        data.showTrailerIcon = !anime.youtubeVideoId.isEmpty
        data.posterImage = anime.posterImage
        data.coverImage = anime.coverImage
        
        //Update if we have the entry or not
        let entry = getEntry()
        data.entryState = entry == nil ? .add : .edit
        
        return data
    }
}

//MARK:- User Gestures
extension AnimeViewController: MediaTableHeaderViewDelegate {
    
    func didTapEntryButton(state: MediaTableHeaderView.EntryButtonState) {
        switch state {
        case .edit:
            if let entry = getEntry() {
                AppCoordinator.showLibraryEntryVC(in: self.navigationController, entry: entry)
            }
            break
            
        case .add:
            break
        }
    }
    
    func didTapTrailerButton() {
        if !anime.youtubeVideoId.isEmpty {
            let id = anime.youtubeVideoId
            AppCoordinator.showYoutubeVideo(videoID: id, in: self)
        }
    }
    
    func didTapCoverImage(_ imageView: UIImageView) {
        MediaViewControllerHelper.tappedImageView(imageView, in: self)
    }
}