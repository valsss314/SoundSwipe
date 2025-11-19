//
//  SongViewModel.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/5/25.
//

import Foundation
import SwiftUI

@MainActor
class SongViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var likedSongs: [Song] = []
    @Published var dislikedSongs: [Song] = []
    @Published var musicFilter = MusicFilter()

    private let spotifyService = SpotifyService.shared
    private let recommendationEngine = CustomRecommendationEngine()
    private var seedGenres: [String] = ["pop", "rock", "indie"]

    var currentSong: Song? {
        guard currentIndex < songs.count else { return nil }
        return songs[currentIndex]
    }

    var hasMoreSongs: Bool {
        currentIndex < songs.count
    }

    // MARK: - Initialization
    init() {
        Task {
            await authenticateAndLoadRecommendations()
        }
    }

    // MARK: - Authentication & Loading
    func authenticateAndLoadRecommendations() async {
        isLoading = true
        errorMessage = nil

        do {
            // Authenticate with Spotify
            try await spotifyService.authenticateWithClientCredentials()

            // Load initial recommendations
            await loadRecommendations()
        } catch {
            errorMessage = "Failed to connect to Spotify: \(error.localizedDescription)"
            print("Error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Load Recommendations (Using Custom Engine)
    func loadRecommendations() async {
        isLoading = true
        errorMessage = nil

        print(" Loading recommendations using custom engine...")

        do {
            // Use custom recommendation engine with current filter
            let tracks = try await recommendationEngine.getPersonalizedRecommendations(limit: 20, filter: musicFilter)

            let newSongs = tracks.map { $0.toSong() }
            songs.append(contentsOf: newSongs)

            print(" Loaded \(newSongs.count) recommendations")

        } catch {
            errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
            print(" Error loading recommendations: \(error)")

            // Ultimate fallback: search for popular tracks
            do {
                let tracks = try await spotifyService.getMixedPopularTracks(
                    genres: seedGenres,
                    limit: 20
                )

                let newSongs = tracks.map { $0.toSong() }
                songs.append(contentsOf: newSongs)

            } catch {
                print(" Fallback also failed: \(error)")
            }
        }

        isLoading = false
    }

    // MARK: - Swipe Actions
    func handleSwipe(direction: SwipeDirection) {
        guard let song = currentSong else { return }

        // Mark as seen in recommendation engine
        markSongAsInteracted(songId: song.id)

        switch direction {
        case .right:
            // User liked the song
            likedSongs.append(song)
            print(" Liked: \(song.name) by \(song.artist)")

        case .left:
            // User disliked the song
            dislikedSongs.append(song)
            print(" Disliked: \(song.name) by \(song.artist)")
        }

        // Move to next song
        currentIndex += 1

        // Load more songs if we're running low
        if songs.count - currentIndex < 5 {
            Task {
                await loadRecommendations()
            }
        }
    }

    // MARK: - Manual Actions
    func likeCurrentSong() {
        handleSwipe(direction: .right)
    }

    func dislikeCurrentSong() {
        handleSwipe(direction: .left)
    }

    // MARK: - Reset
    func reset() {
        songs.removeAll()
        currentIndex = 0
        likedSongs.removeAll()
        dislikedSongs.removeAll()

        Task {
            await loadRecommendations()
        }
    }

    // MARK: - Update Seeds
    func updateSeedGenres(_ genres: [String]) {
        seedGenres = genres
        reset()
    }

    // MARK: - Get Personalized Recommendations (Same as regular now - uses custom engine)
    func loadPersonalizedRecommendations() async {
        // The custom engine already handles personalization based on user's data
        // So this just calls loadRecommendations which uses the engine
        print(" Loading personalized recommendations (via custom engine)...")
        await loadRecommendations()
    }

    // MARK: - Mark song as seen/interacted
    func markSongAsInteracted(songId: String) {
        recommendationEngine.markTrackAsSeen(trackId: songId)
    }

    // MARK: - Clear history
    func clearRecommendationHistory() {
        recommendationEngine.clearSeenTracks()
        print("🗑️ Cleared recommendation history")
    }

    // MARK: - Get stats
    func getRecommendationStats() -> String {
        let seenCount = recommendationEngine.getSeenTrackCount()
        return "Songs discovered: \(seenCount)"
    }
}
