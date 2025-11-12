//
//  LikedSongsView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

struct LikedSongsView: View {
    @ObservedObject var viewModel: SongViewModel
    @StateObject private var authManager = SpotifyAuthManager.shared
    @State private var searchText = ""
    @State private var showExportOptions = false
    @State private var isExporting = false
    @State private var exportMessage = ""
    @State private var showExportAlert = false

    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return viewModel.likedSongs
        } else {
            return viewModel.likedSongs.filter { song in
                song.name.lowercased().contains(searchText.lowercased()) ||
                song.artist.lowercased().contains(searchText.lowercased()) ||
                song.album.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with Title and Export Button
                HStack {
                    Text("Liked Songs")
                        .font(.custom("Rokkitt-Regular", size: 34))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    if !viewModel.likedSongs.isEmpty {
                        Menu {
                            Button(action: {
                                exportToClipboard()
                            }) {
                                Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                            }

                            if authManager.isAuthenticated {
                                Button(action: {
                                    showExportOptions = true
                                }) {
                                    Label("Export to Spotify Playlist", systemImage: "music.note.list")
                                }
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Search Bar
                searchBar

                if viewModel.likedSongs.isEmpty {
                    emptyState
                } else {
                    // Songs List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSongs) { song in
                                SongCardView(
                                    song: song,
                                    albumArtwork: nil
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .alert("Export to Spotify", isPresented: $showExportOptions) {
            Button("Create New Playlist") {
                Task {
                    await exportToSpotifyPlaylist()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Export \(viewModel.likedSongs.count) liked songs to a Spotify playlist?")
        }
        .alert(exportMessage, isPresented: $showExportAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search songs, artists, albums...", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))

            Text("No Liked Songs Yet")
                .font(.custom("Rokkitt-Regular", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Start swiping right on songs you love!")
                .font(.custom("Rokkitt-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Export Functions
    private func exportToClipboard() {
        let songsList = viewModel.likedSongs.map { "\($0.name) by \($0.artist)" }.joined(separator: "\n")
        UIPasteboard.general.string = songsList

        exportMessage = "✅ Copied \(viewModel.likedSongs.count) songs to clipboard"
        showExportAlert = true
        print("✅ Copied \(viewModel.likedSongs.count) songs to clipboard")
    }

    private func exportToSpotifyPlaylist() async {
        isExporting = true

        do {
            // Get track URIs (only songs with Spotify URLs)
            let trackUris = viewModel.likedSongs
                .compactMap { $0.spotifyURL }
                .map { url in
                    // Convert URL to URI format (spotify:track:id)
                    if let trackId = url.split(separator: "/").last {
                        return "spotify:track:\(trackId)"
                    }
                    return nil
                }
                .compactMap { $0 }

            guard !trackUris.isEmpty else {
                exportMessage = "❌ No Spotify tracks found to export"
                showExportAlert = true
                isExporting = false
                return
            }

            // Create playlist
            let playlistName = "SoundSwipe Liked Songs"
            let playlistDescription = "My liked songs from SoundSwipe - \(Date().formatted(date: .abbreviated, time: .omitted))"

            if let playlistId = try await createSpotifyPlaylist(name: playlistName, description: playlistDescription) {
                // Add tracks to playlist
                try await addTracksToPlaylist(playlistId: playlistId, trackUris: trackUris)

                exportMessage = "✅ Successfully exported \(trackUris.count) songs to Spotify playlist '\(playlistName)'"
                showExportAlert = true
                print("✅ Exported to Spotify playlist: \(playlistId)")
            }

        } catch {
            exportMessage = "❌ Failed to export: \(error.localizedDescription)"
            showExportAlert = true
            print("❌ Export error: \(error)")
        }

        isExporting = false
    }

    private func createSpotifyPlaylist(name: String, description: String) async throws -> String? {
        guard let token = authManager.userAccessToken else {
            throw SpotifyError.notAuthenticated
        }

        // First, get current user ID
        let meUrl = URL(string: "https://api.spotify.com/v1/me")!
        var meRequest = URLRequest(url: meUrl)
        meRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (meData, _) = try await URLSession.shared.data(for: meRequest)

        guard let meJson = try? JSONSerialization.jsonObject(with: meData) as? [String: Any],
              let userId = meJson["id"] as? String else {
            throw SpotifyError.invalidResponse
        }

        // Create playlist
        let playlistUrl = URL(string: "https://api.spotify.com/v1/users/\(userId)/playlists")!
        var playlistRequest = URLRequest(url: playlistUrl)
        playlistRequest.httpMethod = "POST"
        playlistRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        playlistRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let playlistBody: [String: Any] = [
            "name": name,
            "description": description,
            "public": false
        ]
        playlistRequest.httpBody = try JSONSerialization.data(withJSONObject: playlistBody)

        let (playlistData, _) = try await URLSession.shared.data(for: playlistRequest)

        if let playlistJson = try? JSONSerialization.jsonObject(with: playlistData) as? [String: Any],
           let playlistId = playlistJson["id"] as? String {
            return playlistId
        }

        return nil
    }

    private func addTracksToPlaylist(playlistId: String, trackUris: [String]) async throws {
        guard let token = authManager.userAccessToken else {
            throw SpotifyError.notAuthenticated
        }

        // Spotify API allows max 100 tracks per request
        let batchSize = 100
        let batches = stride(from: 0, to: trackUris.count, by: batchSize).map {
            Array(trackUris[$0..<min($0 + batchSize, trackUris.count)])
        }

        for batch in batches {
            let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)/tracks")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = ["uris": batch]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 201 {
                print("⚠️ Failed to add batch to playlist: \(httpResponse.statusCode)")
            }
        }
    }
}

#Preview {
    LikedSongsView(viewModel: SongViewModel())
}
