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
    var spotifyURL: String?      // https://open.spotify.com/track/...
    var previewURL: String?      // optional, if you still use MP3 previews
    var durationMS: Int?         // from Spotify's duration_ms
    let spotifyURI: String?      // spotify:track:xyz (for full playback)

    // Convenience initializer for testing/manual creation
    init(
        id: String = UUID().uuidString,
        name: String,
        artist: String,
        album: String,
        albumArtworkURL: String? = nil,
        spotifyURL: String? = nil,
        spotifyURI: String? = nil,
        previewURL: String? = nil,
        durationMS: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.artist = artist
        self.album = album
        self.albumArtworkURL = albumArtworkURL
        self.spotifyURL = spotifyURL
        self.spotifyURI = spotifyURI
        self.previewURL = previewURL
        self.durationMS = durationMS
    }
}

extension Song {
    /// Returns something like "3:27" or "--:--" if unknown
    var durationText: String {
        guard let ms = durationMS else { return "--:--" }
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
