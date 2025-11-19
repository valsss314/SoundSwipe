//
//  CustomRecommendationEngine.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import Foundation

@MainActor
class CustomRecommendationEngine: ObservableObject {
    private let spotifyService = SpotifyService.shared
    private var seenTrackIds: Set<String> = []

    // Cache for artist info
    private var artistGenreCache: [String: [String]] = [:]

    // MARK: - Main Recommendation Function
    func getPersonalizedRecommendations(limit: Int = 20, filter: MusicFilter = MusicFilter()) async throws -> [SpotifyTrack] {
        guard SpotifyAuthManager.shared.isAuthenticated else {
            print(" User not authenticated, falling back to generic recommendations")
            return try await getGenericRecommendations(limit: limit, filter: filter)
        }

        print(" Starting custom recommendation engine...")

        // If filter is active, skip recommendations and do direct search
        if filter.isActive {
            print("🔍 Filter active - using direct search mode")
            print("🔍 Filters: genres=\(filter.selectedGenres.count), years=\(filter.yearRange), popular=\(filter.includePopular), new=\(filter.includeNew), classics=\(filter.includeClassics)")
            return try await getFilteredSearchResults(limit: limit, filter: filter)
        }

        var allTracks: [SpotifyTrack] = []

        // Strategy 1: Get recommendations based on user's top artists
        print(" Strategy 1: Top Artists")
        if let artistTracks = try? await getTracksFromTopArtists(limit: limit / 2, filter: filter) {
            allTracks.append(contentsOf: artistTracks)
            print("    Got \(artistTracks.count) tracks from top artists")
        }

        // Strategy 2: Get recommendations based on similar artists
        print(" Strategy 2: Similar Artists")
        if let similarTracks = try? await getTracksFromSimilarArtists(limit: limit / 3, filter: filter) {
            allTracks.append(contentsOf: similarTracks)
            print("    Got \(similarTracks.count) tracks from similar artists")
        }

        // Strategy 3: Get recommendations based on genres from top artists
        print(" Strategy 3: Genre-based")
        if let genreTracks = try? await getTracksFromGenres(limit: limit / 3, filter: filter) {
            allTracks.append(contentsOf: genreTracks)
            print("    Got \(genreTracks.count) tracks from genres")
        }

        // Strategy 4: Get trending tracks in user's favorite genres
        print(" Strategy 4: Trending in your genres")
        if filter.includeNew || filter.includePopular {
            if let trendingTracks = try? await getTrendingInUserGenres(limit: limit / 4, filter: filter) {
                allTracks.append(contentsOf: trendingTracks)
                print("    Got \(trendingTracks.count) trending tracks")
            }
        }
        
        // Strategy 5: Match reccomended songs with the song analysis of liked songs

        let uniqueTracks = filterAndDeduplicate(tracks: allTracks)

        // Shuffle for variety
        var finalTracks = uniqueTracks.shuffled()

        finalTracks = Array(finalTracks.prefix(limit))


        return finalTracks
    }

    // MARK: - Strategy 1: Top Artists
    private func getTracksFromTopArtists(limit: Int, filter: MusicFilter) async throws -> [SpotifyTrack] {
        var tracks: [SpotifyTrack] = []

        // Get user's top artists
        let topArtistIds = try await spotifyService.getUserTopArtists(limit: 5)

        for artistId in topArtistIds.prefix(3) {
            // Get artist details to find their name
            if let artistName = try? await getArtistName(artistId: artistId) {
                // Build query with year filter if specified
                var query = "artist:\(artistName)"
                if filter.yearRange != 2020...2024 {
                    query += " year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)"
                }

                if let artistTracks = try? await spotifyService.searchTracks(query: query, limit: limit / 3) {
                    tracks.append(contentsOf: artistTracks)
                }
            }
        }

        return tracks
    }

    // MARK: - Strategy 2: Similar Artists
    private func getTracksFromSimilarArtists(limit: Int, filter: MusicFilter) async throws -> [SpotifyTrack] {
        var tracks: [SpotifyTrack] = []

        // Get user's top tracks to extract artist names
        let topTracks = try await spotifyService.getUserTopTracks(limit: 10)

        // Extract unique artists
        let artistNames = Set(topTracks.compactMap { $0.artists.first?.name })

        // For each artist, search for "similar to [artist]"
        for artistName in artistNames.prefix(3) {
            var queries = [
                "\(artistName) similar",
                "like \(artistName)",
                "\(artistName) style"
            ]

            // Apply year filter if specified
            if filter.yearRange != 2020...2024 {
                queries = queries.map { "\($0) year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)" }
            }

            for query in queries {
                if let similarTracks = try? await spotifyService.searchTracks(query: query, limit: 3) {
                    tracks.append(contentsOf: similarTracks)
                }
            }
        }

        return tracks
    }

    // MARK: - Strategy 3: Genre-based
    private func getTracksFromGenres(limit: Int, filter: MusicFilter) async throws -> [SpotifyTrack] {
        var tracks: [SpotifyTrack] = []

        var genres: Set<String> = []

        // If user selected specific genres, use those
        if !filter.selectedGenres.isEmpty {
            genres = Set(filter.selectedGenres)
            print("    Using filtered genres: \(genres.joined(separator: ", "))")
        } else {
            // Otherwise, get user's top artists' genres
            let topArtistIds = try await spotifyService.getUserTopArtists(limit: 5)

            for artistId in topArtistIds {
                if let artistGenres = try? await getArtistGenres(artistId: artistId) {
                    genres.formUnion(artistGenres)
                }
            }
            print("    User's favorite genres: \(genres.joined(separator: ", "))")
        }

        // Search for tracks in these genres
        for genre in genres.prefix(5) {
            var queries: [String] = []

            // Build queries based on filter settings
            if filter.includeNew {
                queries.append("genre:\"\(genre)\" year:\(max(filter.yearRange.upperBound - 1, filter.yearRange.lowerBound))-\(filter.yearRange.upperBound)")
            }

            if filter.includeClassics {
                queries.append("genre:\"\(genre)\" year:\(filter.yearRange.lowerBound)-\(min(filter.yearRange.lowerBound + 10, filter.yearRange.upperBound))")
            }

            if filter.includePopular {
                queries.append("\(genre) popular year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)")
            }

            // If no quick filters, use default year range
            if queries.isEmpty {
                queries.append("genre:\"\(genre)\" year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)")
            }

            for query in queries {
                if let genreTracks = try? await spotifyService.searchTracks(query: query, limit: limit / (genres.count * queries.count)) {
                    tracks.append(contentsOf: genreTracks)
                }
            }
        }

        return tracks
    }

    // MARK: - Strategy 4: Trending
    private func getTrendingInUserGenres(limit: Int, filter: MusicFilter) async throws -> [SpotifyTrack] {
        var tracks: [SpotifyTrack] = []

        // Get user's top tracks to extract keywords
        let topTracks = try await spotifyService.getUserTopTracks(limit: 5)

        // Extract common words from track names (excluding common words)
        let stopWords = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for"]
        var keywords: [String] = []

        for track in topTracks {
            let words = track.name.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 3 && !stopWords.contains($0) }
            keywords.append(contentsOf: words)
        }

        // Get most common keywords
        let wordCounts = Dictionary(grouping: keywords, by: { $0 }).mapValues { $0.count }
        let topKeywords = wordCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }

        // Search for trending tracks with these keywords
        for keyword in topKeywords {
            var query = "\(keyword)"

            // Apply year filter
            if filter.includeNew {
                query += " year:\(max(filter.yearRange.upperBound - 1, filter.yearRange.lowerBound))-\(filter.yearRange.upperBound)"
            } else {
                query += " year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)"
            }

            if let trendingTracks = try? await spotifyService.searchTracks(query: query, limit: limit / 3) {
                tracks.append(contentsOf: trendingTracks)
            }
        }

        return tracks
    }

    // MARK: - Fallback: Generic Recommendations
    private func getGenericRecommendations(limit: Int, filter: MusicFilter) async throws -> [SpotifyTrack] {
        // Use filtered genres if specified, otherwise use defaults
        let genres = filter.selectedGenres.isEmpty ? ["pop", "rock", "indie", "hip-hop", "electronic"] : filter.selectedGenres
        var tracks: [SpotifyTrack] = []

        for genre in genres {
            let query = "genre:\(genre) year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)"
            if let genreTracks = try? await spotifyService.searchTracks(query: query, limit: limit / genres.count) {
                tracks.append(contentsOf: genreTracks)
            }
        }

        return Array(tracks.shuffled().prefix(limit))
    }

    // MARK: - Direct Search Mode (when filters are active)
    private func getFilteredSearchResults(limit: Int, filter: MusicFilter) async throws -> [SpotifyTrack] {
        var tracks: [SpotifyTrack] = []

        // Determine which genres to search
        let genres: [String]
        if filter.selectedGenres.isEmpty {
            // No specific genres selected, search across popular genres
            genres = ["pop", "rock", "indie", "hip-hop", "electronic"]
        } else {
            genres = filter.selectedGenres
        }

        let tracksPerGenre = max(limit / genres.count, 5)

        for genre in genres {
            var queries: [String] = []

            // Build queries based on quick filter settings
            if filter.includeNew {
                // New releases: last 1-2 years of the range
                let newYear = max(filter.yearRange.upperBound - 1, filter.yearRange.lowerBound)
                queries.append("genre:\"\(genre)\" year:\(newYear)-\(filter.yearRange.upperBound)")
            }

            if filter.includeClassics {
                // Classics: first 10 years of the range
                let classicEnd = min(filter.yearRange.lowerBound + 10, filter.yearRange.upperBound)
                queries.append("genre:\"\(genre)\" year:\(filter.yearRange.lowerBound)-\(classicEnd)")
            }

            if filter.includePopular {
                // Popular tracks in the year range
                queries.append("genre:\"\(genre)\" year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)")
            }

            // If no quick filters are selected, just search by genre and year
            if queries.isEmpty {
                queries.append("genre:\"\(genre)\" year:\(filter.yearRange.lowerBound)-\(filter.yearRange.upperBound)")
            }

            // Execute searches
            for query in queries {
                let queryLimit = tracksPerGenre / queries.count
                if let searchResults = try? await spotifyService.searchTracks(query: query, limit: max(queryLimit, 3)) {
                    tracks.append(contentsOf: searchResults)
                    print("    Search '\(query)' returned \(searchResults.count) tracks")
                }
            }
        }

        // Filter and deduplicate
        let uniqueTracks = filterAndDeduplicate(tracks: tracks)

        // Shuffle and return
        return Array(uniqueTracks.shuffled().prefix(limit))
    }

    // MARK: - Helper Functions
    private func getArtistName(artistId: String) async throws -> String {
        guard let token = await spotifyService.getActiveToken() else {
            throw SpotifyError.notAuthenticated
        }

        let url = URL(string: "https://api.spotify.com/v1/artists/\(artistId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["name"] as? String {
            return name
        }

        throw SpotifyError.invalidResponse
    }

    private func getArtistGenres(artistId: String) async throws -> [String] {
        // Check cache first
        if let cached = artistGenreCache[artistId] {
            return cached
        }

        guard let token = await spotifyService.getActiveToken() else {
            throw SpotifyError.notAuthenticated
        }

        let url = URL(string: "https://api.spotify.com/v1/artists/\(artistId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let genres = json["genres"] as? [String] {
            // Cache for future use
            artistGenreCache[artistId] = genres
            return genres
        }

        return []
    }

    private func filterAndDeduplicate(tracks: [SpotifyTrack]) -> [SpotifyTrack] {
        var uniqueTracks: [SpotifyTrack] = []
        var seenIds: Set<String> = []

        for track in tracks {
            // Skip if already seen
            if seenTrackIds.contains(track.id) {
                continue
            }

            // Skip if duplicate in current batch
            if seenIds.contains(track.id) {
                continue
            }

            uniqueTracks.append(track)
            seenIds.insert(track.id)
        }

        // Add to permanent seen list
        seenTrackIds.formUnion(seenIds)

        return uniqueTracks
    }

    // MARK: - Public Helpers
    func markTrackAsSeen(trackId: String) {
        seenTrackIds.insert(trackId)
    }

    func clearSeenTracks() {
        seenTrackIds.removeAll()
        print(" Cleared seen tracks history")
    }

    func getSeenTrackCount() -> Int {
        return seenTrackIds.count
    }
}
