//
//  Playlists.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/5/25.
//

import Foundation

struct Playlist: Identifiable {
    let id: String // Spotify playlist ID
    let name: String
    let description: String?
    let imageURL: String?
    var songCount: Int
    let owner: String?
    let isPublic: Bool

    init(id: String, name: String, description: String? = nil, imageURL: String? = nil, songCount: Int = 0, owner: String? = nil, isPublic: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.songCount = songCount
        self.owner = owner
        self.isPublic = isPublic
    }
}
