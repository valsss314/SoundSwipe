//
//  Song.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/5/25.
//

import Foundation

struct Song: Identifiable {
    let id: String
    var name: String
    var artist: String
    var album: String
    var albumArtworkURL: String?
    var spotifyURL: String?
    var previewURL: String?

    // Convenience initializer for testing/manual creation
    init(id: String = UUID().uuidString, name: String, artist: String, album: String, albumArtworkURL: String? = nil, spotifyURL: String? = nil, previewURL: String? = nil) {
        self.id = id
        self.name = name
        self.artist = artist
        self.album = album
        self.albumArtworkURL = albumArtworkURL
        self.spotifyURL = spotifyURL
        self.previewURL = previewURL
    }
}
