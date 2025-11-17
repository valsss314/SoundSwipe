//
//  ProfileView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = SpotifyAuthManager.shared
    @StateObject private var spotifyService = SpotifyService.shared
    @ObservedObject var viewModel: SongViewModel

    @State private var topTracks: [SpotifyTrack] = []
    @State private var topArtists: [(name: String, genres: [String])] = []
    @State private var isLoadingStats = false

    var body: some View {
        NavigationView {
            ZStack {

                ScrollView {
                    VStack(spacing: 25) {
                        // Profile Header
                        profileHeader

                        // Swipe Stats
                        swipeStatsSection

                        Divider().background(Color.white.opacity(0.2))

                        // Spotify Stats
                        if authManager.isAuthenticated {
                            spotifyStatsSection
                        }

                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
            .background(
                backgroundWithFades
            )
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if authManager.isAuthenticated {
                    Task {
                        await loadSpotifyStats()
                    }
                }
            }
        }
    }
    
    private var backgroundWithFades: some View {
            ZStack {
                dynamicBackground
            }
            .ignoresSafeArea()  // <- make the base fill the whole screen
            .overlay(
                // TOP fade
                LinearGradient(
                    colors: [
                        Color.black.opacity(1),
                        Color.black.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea(edges: .top)      // <- push into the top corners
            )
            .overlay(
                // BOTTOM fade
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(1)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)   // <- push into the bottom corners
            )
        }
    
    private var dynamicBackground: some View {
        Group {
            if let song = viewModel.currentSong,
               let urlString = song.albumArtworkURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        fallbackBackground
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 40)
                            .overlay(Color.black.opacity(0.35))
                    case .failure:
                        fallbackBackground
                    @unknown default:
                        fallbackBackground
                    }
                }
            } else {
                fallbackBackground
            }
        }
    }

    private var fallbackBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.05, green: 0.07, blue: 0.10),
                Color(red: 0.08, green: 0.15, blue: 0.08)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            // User Info
            if let userName = authManager.userDisplayName {
                Text(userName)
                    .font(.custom("Rokkitt-Regular", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            if authManager.isAuthenticated {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Connected to Spotify")
                        .font(.custom("Rokkitt-Regular", size: 14))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Swipe Stats Section
    private var swipeStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Your Swipe Stats")
                    .font(.custom("Rokkitt-Regular", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                StatCard(
                    icon: "heart.fill",
                    title: "Liked",
                    value: "\(viewModel.likedSongs.count)",
                    color: .green
                )

                StatCard(
                    icon: "xmark",
                    title: "Passed",
                    value: "\(viewModel.dislikedSongs.count)",
                    color: .red
                )

                StatCard(
                    icon: "music.note",
                    title: "Discovered",
                    value: "\(viewModel.likedSongs.count + viewModel.dislikedSongs.count)",
                    color: .purple
                )

                StatCard(
                    icon: "percent",
                    title: "Like Rate",
                    value: likePercentage,
                    color: .blue
                )
            }

            // Liked Songs Preview
            if !viewModel.likedSongs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recently Liked")
                        .font(.custom("Rokkitt-Regular", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    ForEach(viewModel.likedSongs.suffix(3)) { song in
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(.green)

                            VStack(alignment: .leading) {
                                Text(song.name)
                                    .font(.custom("Rokkitt-Regular", size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(song.artist)
                                    .font(.custom("Rokkitt-Regular", size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    // MARK: - Spotify Stats Section
    private var spotifyStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.green)
                Text("Spotify Stats")
                    .font(.custom("Rokkitt-Regular", size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if isLoadingStats {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                }
            }

            // Top Tracks
            if !topTracks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Top Tracks")
                        .font(.custom("Rokkitt-Regular", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    ForEach(Array(topTracks.prefix(5).enumerated()), id: \.element.id) { index, track in
                        HStack {
                            Text("\(index + 1)")
                                .font(.custom("Rokkitt-Regular", size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.name)
                                    .font(.custom("Rokkitt-Regular", size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(track.artists.first?.name ?? "Unknown")
                                    .font(.custom("Rokkitt-Regular", size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            }

            // Top Artists
            if !topArtists.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Top Artists")
                        .font(.custom("Rokkitt-Regular", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    ForEach(Array(topArtists.prefix(5).enumerated()), id: \.offset) { index, artist in
                        HStack {
                            Text("\(index + 1)")
                                .font(.custom("Rokkitt-Regular", size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(artist.name)
                                    .font(.custom("Rokkitt-Regular", size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                if !artist.genres.isEmpty {
                                    Text(artist.genres.prefix(2).joined(separator: ", "))
                                        .font(.custom("Rokkitt-Regular", size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            }

            if topTracks.isEmpty && topArtists.isEmpty && !isLoadingStats {
                Text("No Spotify stats available yet. Keep listening!")
                    .font(.custom("Rokkitt-Regular", size: 14))
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Export Liked Songs
            Button(action: {
                exportLikedSongs()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Liked Songs")
                        .font(.custom("Rokkitt-Regular", size: 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }

            // Clear History
            Button(action: {
                clearHistory()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Swipe History")
                        .font(.custom("Rokkitt-Regular", size: 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.7))
                .cornerRadius(12)
            }

            // Logout
            if authManager.isAuthenticated {
                Button(action: {
                    authManager.logout()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout from Spotify")
                            .font(.custom("Rokkitt-Regular", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Computed Properties
    private var likePercentage: String {
        let total = viewModel.likedSongs.count + viewModel.dislikedSongs.count
        guard total > 0 else { return "0%" }
        let percentage = Double(viewModel.likedSongs.count) / Double(total) * 100
        return String(format: "%.0f%%", percentage)
    }

    // MARK: - Functions
    private func loadSpotifyStats() async {
        isLoadingStats = true

        do {
            // Load top tracks
            topTracks = try await spotifyService.getUserTopTracks(limit: 10)

            // Load top artists with details
            let artistIds = try await spotifyService.getUserTopArtists(limit: 5)

            var artists: [(name: String, genres: [String])] = []
            for artistId in artistIds {
                if let token = await spotifyService.getActiveToken() {
                    let url = URL(string: "https://api.spotify.com/v1/artists/\(artistId)")!
                    var request = URLRequest(url: url)
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                    if let (data, _) = try? await URLSession.shared.data(for: request),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let name = json["name"] as? String,
                       let genres = json["genres"] as? [String] {
                        artists.append((name: name, genres: genres))
                    }
                }
            }
            topArtists = artists

        } catch {
            print("❌ Error loading Spotify stats: \(error)")
        }

        isLoadingStats = false
    }

    private func exportLikedSongs() {
        let songsList = viewModel.likedSongs.map { "\($0.name) by \($0.artist)" }.joined(separator: "\n")
        UIPasteboard.general.string = songsList
        print("✅ Copied \(viewModel.likedSongs.count) songs to clipboard")
    }

    private func clearHistory() {
        viewModel.reset()
        print("🗑️ Cleared swipe history")
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)

            Text(value)
                .font(.custom("Rokkitt-Regular", size: 28))
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.custom("Rokkitt-Regular", size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

#Preview {
    ProfileView(viewModel: SongViewModel())
}
