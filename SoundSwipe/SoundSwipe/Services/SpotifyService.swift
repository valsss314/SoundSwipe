//
//  SpotifyService.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import Foundation

// MARK: - Spotify API Models
struct SpotifyTrack: Codable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let duration_ms: Int
    let preview_url: String?
    let external_urls: SpotifyExternalURLs
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
}

struct SpotifyAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyExternalURLs: Codable {
    let spotify: String
}

struct SpotifyRecommendationsResponse: Codable {
    let tracks: [SpotifyTrack]
}

struct SpotifyAuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

// MARK: - Spotify Service
class SpotifyService: ObservableObject {
    static let shared = SpotifyService()

    @Published var isAuthenticated = false
    @Published var accessToken: String?

    private let clientId = "3acdddba753b4ad58671235171d1996b"
    private let clientSecret = "d208c8b765a645ff87b7254518cfe44a"
    private let baseURL = "https://api.spotify.com/v1"

    private init() {}

    // MARK: - Get Active Token (User or Client Credentials)
    func getActiveToken() async -> String? {
        // Try to use user token first
      if let userToken = await SpotifyAuthManager.shared.userAccessToken {
            return userToken
        }

        // Fallback to client credentials
        if let clientToken = accessToken, isAuthenticated {
            return clientToken
        }

        // Try to authenticate with client credentials
        do {
            try await authenticateWithClientCredentials()
            return accessToken
        } catch {
            print(" Failed to get token: \(error)")
            return nil
        }
    }

    // MARK: - Authentication
    func authenticateWithClientCredentials() async throws {
        let authURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"

        // Create authorization header
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Set body
        let body = "grant_type=client_credentials"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print(" Auth: Invalid response type")
            throw SpotifyError.authenticationFailed
        }

        print(" Auth Response Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print(" Auth Error Response: \(errorString)")
            }
            throw SpotifyError.authenticationFailed
        }

        let authResponse = try JSONDecoder().decode(SpotifyAuthResponse.self, from: data)
        print(" Successfully authenticated with Spotify")

        await MainActor.run {
            self.accessToken = authResponse.access_token
            self.isAuthenticated = true
        }

        // Test the token by getting available genres
        do {
            let genres = try await getAvailableGenreSeeds()
            print(" Token verified. Available genres count: \(genres.count)")
        } catch {
            print(" Warning: Could not fetch genre seeds: \(error)")
        }
    }

    // MARK: - Get Recommendations
    func getRecommendations(
        seedTracks: [String]? = nil,
        seedArtists: [String]? = nil,
        seedGenres: [String]? = nil,
        limit: Int = 20
    ) async throws -> [SpotifyTrack] {
        guard let token = await getActiveToken() else {
            throw SpotifyError.notAuthenticated
        }

        // Validate that we have at least one seed
        let hasSeeds = (seedTracks?.isEmpty == false) ||
                       (seedArtists?.isEmpty == false) ||
                       (seedGenres?.isEmpty == false)

        guard hasSeeds else {
            print(" No seeds provided for recommendations")
            throw SpotifyError.invalidResponse
        }

        var components = URLComponents(string: "\(baseURL)/recommendations")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "market", value: "US") // Add market parameter
        ]

        if let seedTracks = seedTracks, !seedTracks.isEmpty {
            queryItems.append(URLQueryItem(name: "seed_tracks", value: seedTracks.joined(separator: ",")))
            print(" Using seed tracks: \(seedTracks.joined(separator: ", "))")
        }

        if let seedArtists = seedArtists, !seedArtists.isEmpty {
            queryItems.append(URLQueryItem(name: "seed_artists", value: seedArtists.joined(separator: ",")))
            print(" Using seed artists: \(seedArtists.joined(separator: ", "))")
        }

        if let seedGenres = seedGenres, !seedGenres.isEmpty {
            queryItems.append(URLQueryItem(name: "seed_genres", value: seedGenres.joined(separator: ",")))
            print(" Using seed genres: \(seedGenres.joined(separator: ", "))")
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            print("Invalid URL for recommendations")
          throw SpotifyError.requestFailed()
        }

        print(" Requesting recommendations from: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print(" Invalid response type")
            throw SpotifyError.requestFailed()
        }

        print(" Recommendations Response Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print(" Recommendations Error Response: \(errorString)")
            }
            throw SpotifyError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let recommendationsResponse = try JSONDecoder().decode(SpotifyRecommendationsResponse.self, from: data)
        print(" Received \(recommendationsResponse.tracks.count) recommendations")
        return recommendationsResponse.tracks
    }

    // MARK: - Search Tracks
    func searchTracks(query: String, limit: Int = 20) async throws -> [SpotifyTrack] {
        guard let token = await getActiveToken() else {
            throw SpotifyError.notAuthenticated
        }

        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.requestFailed()
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print(" Search Error Response: \(errorString)")
            }
            throw SpotifyError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let tracksData = json?["tracks"] as? [String: Any]
        let items = tracksData?["items"] as? [[String: Any]]

        let tracksJSON = try JSONSerialization.data(withJSONObject: items ?? [])
        let tracks = try JSONDecoder().decode([SpotifyTrack].self, from: tracksJSON)

        return tracks
    }

    // MARK: - Get Available Genre Seeds
    func getAvailableGenreSeeds() async throws -> [String] {
        guard let token = await getActiveToken() else {
            throw SpotifyError.notAuthenticated
        }

        let url = URL(string: "\(baseURL)/recommendations/available-genre-seeds")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.requestFailed()
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print(" Genre Seeds Error Response: \(errorString)")
            }
            throw SpotifyError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["genres"] as? [String] ?? []
    }

    // MARK: - Get Popular Tracks (Alternative to Recommendations)
    func getPopularTracksByGenre(genre: String, limit: Int = 20) async throws -> [SpotifyTrack] {
        // Use search with genre as a workaround
        let queries = [
            "genre:\(genre) year:2023-2024",
            "genre:\(genre) year:2022-2023",
            "\(genre) popular",
            "\(genre) top"
        ]

        // Try different search queries until we get results
        for query in queries {
            do {
                print("🔍 Searching with query: \(query)")
                let tracks = try await searchTracks(query: query, limit: limit)
                if !tracks.isEmpty {
                    print(" Found \(tracks.count) tracks")
                    return tracks
                }
            } catch {
                print(" Search failed for query '\(query)': \(error)")
                continue
            }
        }

        throw SpotifyError.requestFailed()
    }

    // MARK: - Get Mixed Popular Tracks
    func getMixedPopularTracks(genres: [String], limit: Int = 20) async throws -> [SpotifyTrack] {
        var allTracks: [SpotifyTrack] = []
        let tracksPerGenre = max(1, limit / genres.count)

        print(" Getting tracks for genres: \(genres.joined(separator: ", "))")

        for genre in genres {
            do {
                let tracks = try await getPopularTracksByGenre(genre: genre, limit: tracksPerGenre)
                allTracks.append(contentsOf: tracks)
            } catch {
                print(" Failed to get tracks for genre '\(genre)': \(error)")
            }
        }

        // Shuffle to mix genres
        allTracks.shuffle()

        // Return requested limit
        return Array(allTracks.prefix(limit))
    }

    // MARK: - Get User's Top Tracks (Requires User Auth)
    func getUserTopTracks(limit: Int = 20, timeRange: String = "medium_term") async throws -> [SpotifyTrack] {
        guard let token = await getActiveToken() else {
            throw SpotifyError.notAuthenticated
        }

        let url = URL(string: "\(baseURL)/me/top/tracks?limit=\(limit)&time_range=\(timeRange)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.requestFailed()
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print(" Top Tracks Error: \(errorString)")
            }
            throw SpotifyError.requestFailed(statusCode: httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let items = json["items"] as? [[String: Any]] {
            let tracksJSON = try JSONSerialization.data(withJSONObject: items)
            let tracks = try JSONDecoder().decode([SpotifyTrack].self, from: tracksJSON)
            return tracks
        }

        throw SpotifyError.invalidResponse
    }

    // MARK: - Get User's Top Artists (Requires User Auth)
    func getUserTopArtists(limit: Int = 5, timeRange: String = "medium_term") async throws -> [String] {
        guard let token = await getActiveToken() else {
            throw SpotifyError.notAuthenticated
        }

        let url = URL(string: "\(baseURL)/me/top/artists?limit=\(limit)&time_range=\(timeRange)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.requestFailed()
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print(" Top Artists Error: \(errorString)")
            }
            throw SpotifyError.requestFailed(statusCode: httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let items = json["items"] as? [[String: Any]] {
            return items.compactMap { $0["id"] as? String }
        }

        throw SpotifyError.invalidResponse
    }
}

// MARK: - Spotify Error
enum SpotifyError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case requestFailed(statusCode: Int? = nil)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Spotify"
        case .authenticationFailed:
            return "Failed to authenticate with Spotify"
        case .requestFailed(let statusCode):
            if let code = statusCode {
                return "Spotify API request failed with status code: \(code)"
            }
            return "Spotify API request failed"
        case .invalidResponse:
            return "Invalid response from Spotify"
        }
    }
}

// MARK: - Extension to convert SpotifyTrack to Song
extension SpotifyTrack {
    func toSong() -> Song {
        Song(
            id: self.id,
            name: self.name,
            artist: self.artists.first?.name ?? "Unknown Artist",
            album: self.album.name,
            albumArtworkURL: self.album.images.first?.url,
            spotifyURL: self.external_urls.spotify,
            previewURL: self.preview_url
        )
    }
}
