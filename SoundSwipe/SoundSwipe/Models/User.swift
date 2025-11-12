//
//  User.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/5/25.
//

import Foundation

struct User: Identifiable {
    let id: String // Spotify user ID
    let username: String
    let email: String?
    let displayName: String?
    let imageURL: String?

    var likedSongs: [Song]
    var playlists: [Playlist]

    // Initialize from Spotify data
    init(id: String, username: String, email: String? = nil, displayName: String? = nil, imageURL: String? = nil, likedSongs: [Song] = [], playlists: [Playlist] = []) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.imageURL = imageURL
        self.likedSongs = likedSongs
        self.playlists = playlists
    }
}

// User stats for tracking app usage
struct UserStats {
    var totalSwipes: Int = 0
    var totalLikes: Int = 0
    var totalDislikes: Int = 0
    var songsDiscovered: Int = 0
    var favoriteGenres: [String] = []
    var topArtists: [String] = []
    var swipeStreak: Int = 0
    var lastSwipeDate: Date?

    var likePercentage: Double {
        guard totalSwipes > 0 else { return 0 }
        return Double(totalLikes) / Double(totalSwipes) * 100
    }

    mutating func recordSwipe(liked: Bool) {
        totalSwipes += 1
        if liked {
            totalLikes += 1
        } else {
            totalDislikes += 1
        }

        // Update streak
        if let lastDate = lastSwipeDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastDate) {
                swipeStreak += 1
            } else if calendar.isDateInYesterday(lastDate) {
                swipeStreak += 1
            } else {
                swipeStreak = 1
            }
        } else {
            swipeStreak = 1
        }

        lastSwipeDate = Date()
    }
}
