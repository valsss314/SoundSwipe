//
//  SpotifyTestView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

struct SpotifyTestView: View {
    @StateObject private var spotifyService = SpotifyService.shared
    @StateObject private var authManager = SpotifyAuthManager.shared
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Token Status
                        tokenStatusCard

                        // Run Tests Button
                        Button(action: {
                            Task {
                                await runAllTests()
                            }
                        }) {
                            HStack {
                                if isRunningTests {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                }

                                Text(isRunningTests ? "Running Tests..." : "Run API Tests")
                                    .font(.custom("Rokkitt-Regular", size: 18))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                        }
                        .disabled(isRunningTests)
                        .padding(.horizontal)

                        // Test Results
                        if !testResults.isEmpty {
                            VStack(spacing: 15) {
                                ForEach(testResults) { result in
                                    TestResultCard(result: result)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Spotify API Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var tokenStatusCard: some View {
        VStack(spacing: 15) {
            // User Authentication Status
            HStack {
                Image(systemName: authManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(authManager.isAuthenticated ? .green : .red)

                VStack(alignment: .leading, spacing: 5) {
                    Text("User Authentication")
                        .font(.custom("Rokkitt-Regular", size: 18))
                        .foregroundColor(.white)

                    if let userName = authManager.userDisplayName {
                        Text("Logged in as \(userName)")
                            .font(.custom("Rokkitt-Regular", size: 14))
                            .foregroundColor(.green)
                    } else {
                        Text("Not logged in")
                            .font(.custom("Rokkitt-Regular", size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Divider().background(Color.white.opacity(0.3))

            // Client Credentials Status
            HStack {
                Image(systemName: spotifyService.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(spotifyService.isAuthenticated ? .green : .red)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Client Credentials (Fallback)")
                        .font(.custom("Rokkitt-Regular", size: 16))
                        .foregroundColor(.white)

                    Text(spotifyService.isAuthenticated ? "Active" : "Not Active")
                        .font(.custom("Rokkitt-Regular", size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Show tokens
            if let userToken = authManager.userAccessToken {
                VStack(alignment: .leading, spacing: 5) {
                    Text("User Token:")
                        .font(.custom("Rokkitt-Regular", size: 14))
                        .foregroundColor(.secondary)

                    Text("\(userToken.prefix(50))...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let clientToken = spotifyService.accessToken {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Client Token:")
                        .font(.custom("Rokkitt-Regular", size: 14))
                        .foregroundColor(.secondary)

                    Text("\(clientToken.prefix(50))...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal)
    }

    private func runAllTests() async {
        isRunningTests = true
        testResults.removeAll()

        // Test 1: Authentication
        await testAuthentication()

        // Test 2: Available Genre Seeds
        await testGenreSeeds()

        // Test 3: Search
        await testSearch()

        // Test 4: Get Track by ID
        await testGetTrack()

        // Test 5: Recommendations
        await testRecommendations()

        // Test 6: Browse New Releases
        await testNewReleases()

        // Test 7: Current User Profile (/me) - WILL FAIL with Client Credentials
        await testCurrentUser()

        // Test 8: Top Artists - WILL FAIL with Client Credentials
        await testTopArtists()

        // Test 9: Top Tracks - WILL FAIL with Client Credentials
        await testTopTracks()

        isRunningTests = false
    }

    private func testAuthentication() async {
        do {
            try await spotifyService.authenticateWithClientCredentials()
            await addResult(TestResult(
                name: "Authentication",
                status: .success,
                message: "Successfully authenticated with Spotify",
                details: "Token obtained and stored"
            ))
        } catch {
            await addResult(TestResult(
                name: "Authentication",
                status: .failure,
                message: "Failed to authenticate",
                details: error.localizedDescription
            ))
        }
    }

    private func testGenreSeeds() async {
        do {
            let genres = try await spotifyService.getAvailableGenreSeeds()
            await addResult(TestResult(
                name: "Genre Seeds",
                status: .success,
                message: "Retrieved \(genres.count) genre seeds",
                details: genres.prefix(10).joined(separator: ", ")
            ))
        } catch {
            await addResult(TestResult(
                name: "Genre Seeds",
                status: .failure,
                message: "Failed to get genre seeds",
                details: error.localizedDescription
            ))
        }
    }

    private func testSearch() async {
        do {
            let tracks = try await spotifyService.searchTracks(query: "pop 2024", limit: 5)
            await addResult(TestResult(
                name: "Search",
                status: .success,
                message: "Found \(tracks.count) tracks",
                details: tracks.map { $0.name }.joined(separator: ", ")
            ))
        } catch {
            await addResult(TestResult(
                name: "Search",
                status: .failure,
                message: "Search failed",
                details: error.localizedDescription
            ))
        }
    }

    private func testGetTrack() async {
        do {
            guard let token = await spotifyService.getActiveToken() else {
                await addResult(TestResult(
                    name: "Get Track",
                    status: .failure,
                    message: "No access token",
                    details: "Authentication required"
                ))
                return
            }

            let url = URL(string: "https://api.spotify.com/v1/tracks/11dFghVXANMlKmJXsNCbNl")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                await addResult(TestResult(
                    name: "Get Track",
                    status: .failure,
                    message: "Failed to get track",
                    details: errorString
                ))
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["name"] as? String,
               let artists = json["artists"] as? [[String: Any]],
               let artistName = artists.first?["name"] as? String {
                await addResult(TestResult(
                    name: "Get Track",
                    status: .success,
                    message: "Successfully retrieved track",
                    details: "\(name) by \(artistName)"
                ))
            }
        } catch {
            await addResult(TestResult(
                name: "Get Track",
                status: .failure,
                message: "Request failed",
                details: error.localizedDescription
            ))
        }
    }

    private func testRecommendations() async {
        do {
            let tracks = try await spotifyService.getRecommendations(
                seedGenres: ["pop", "rock"],
                limit: 5
            )
            await addResult(TestResult(
                name: "Recommendations",
                status: .success,
                message: "Got \(tracks.count) recommendations",
                details: tracks.map { $0.name }.joined(separator: ", ")
            ))
        } catch {
            await addResult(TestResult(
                name: "Recommendations",
                status: .failure,
                message: "Recommendations failed",
                details: error.localizedDescription
            ))
        }
    }

    private func testNewReleases() async {
        do {
            guard let token = await spotifyService.getActiveToken() else {
                await addResult(TestResult(
                    name: "New Releases",
                    status: .failure,
                    message: "No access token",
                    details: "Authentication required"
                ))
                return
            }

            let url = URL(string: "https://api.spotify.com/v1/browse/new-releases?limit=5")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                await addResult(TestResult(
                    name: "New Releases",
                    status: .failure,
                    message: "Failed (Status: \(statusCode))",
                    details: errorString
                ))
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let albums = json["albums"] as? [String: Any],
               let items = albums["items"] as? [[String: Any]] {
                let albumNames = items.compactMap { $0["name"] as? String }
                await addResult(TestResult(
                    name: "New Releases",
                    status: .success,
                    message: "Found \(items.count) new releases",
                    details: albumNames.prefix(3).joined(separator: ", ")
                ))
            }
        } catch {
            await addResult(TestResult(
                name: "New Releases",
                status: .failure,
                message: "Request failed",
                details: error.localizedDescription
            ))
        }
    }

    private func testCurrentUser() async {
        do {
            guard let token = authManager.userAccessToken else {
                await addResult(TestResult(
                    name: "Current User (/me)",
                    status: .failure,
                    message: "No user token - please login with Spotify",
                    details: "This endpoint requires user authentication via Authorization Code Flow"
                ))
                return
            }

            let url = URL(string: "https://api.spotify.com/v1/me")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await addResult(TestResult(
                    name: "Current User (/me)",
                    status: .failure,
                    message: "Invalid response",
                    details: "Could not parse HTTP response"
                ))
                return
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let displayName = json["display_name"] as? String,
                   let email = json["email"] as? String {
                    await addResult(TestResult(
                        name: "Current User (/me)",
                        status: .success,
                        message: "User profile retrieved!",
                        details: "Name: \(displayName), Email: \(email)"
                    ))
                }
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? "No error details"
                await addResult(TestResult(
                    name: "Current User (/me)",
                    status: .failure,
                    message: "❌ EXPECTED: Requires user login (Status: \(httpResponse.statusCode))",
                    details: "This endpoint needs Authorization Code Flow, not Client Credentials. Error: \(errorString)"
                ))
            }
        } catch {
            await addResult(TestResult(
                name: "Current User (/me)",
                status: .failure,
                message: "Request failed",
                details: error.localizedDescription
            ))
        }
    }

    private func testTopArtists() async {
        do {
            guard let token = authManager.userAccessToken else {
                await addResult(TestResult(
                    name: "Top Artists",
                    status: .failure,
                    message: "No user token - please login with Spotify",
                    details: "This endpoint requires user authentication via Authorization Code Flow"
                ))
                return
            }

            let url = URL(string: "https://api.spotify.com/v1/me/top/artists?limit=5")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await addResult(TestResult(
                    name: "Top Artists",
                    status: .failure,
                    message: "Invalid response",
                    details: "Could not parse HTTP response"
                ))
                return
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    let artistNames = items.compactMap { $0["name"] as? String }
                    await addResult(TestResult(
                        name: "Top Artists",
                        status: .success,
                        message: "Your top artists:",
                        details: artistNames.joined(separator: ", ")
                    ))
                }
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? "No error details"
                await addResult(TestResult(
                    name: "Top Artists",
                    status: .failure,
                    message: " EXPECTED: Requires user login (Status: \(httpResponse.statusCode))",
                    details: "This endpoint needs Authorization Code Flow, not Client Credentials. Error: \(errorString)"
                ))
            }
        } catch {
            await addResult(TestResult(
                name: "Top Artists",
                status: .failure,
                message: "Request failed",
                details: error.localizedDescription
            ))
        }
    }

    private func testTopTracks() async {
        do {
            guard let token = authManager.userAccessToken else {
                await addResult(TestResult(
                    name: "Top Tracks",
                    status: .failure,
                    message: "No user token - please login with Spotify",
                    details: "This endpoint requires user authentication via Authorization Code Flow"
                ))
                return
            }

            let url = URL(string: "https://api.spotify.com/v1/me/top/tracks?limit=5")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await addResult(TestResult(
                    name: "Top Tracks",
                    status: .failure,
                    message: "Invalid response",
                    details: "Could not parse HTTP response"
                ))
                return
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    let trackInfo = items.compactMap { item -> String? in
                        guard let name = item["name"] as? String,
                              let artists = item["artists"] as? [[String: Any]],
                              let artistName = artists.first?["name"] as? String else {
                            return nil
                        }
                        return "\(name) by \(artistName)"
                    }
                    await addResult(TestResult(
                        name: "Top Tracks",
                        status: .success,
                        message: "Your top tracks:",
                        details: trackInfo.joined(separator: ", ")
                    ))
                }
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? "No error details"
                await addResult(TestResult(
                    name: "Top Tracks",
                    status: .failure,
                    message: "❌ EXPECTED: Requires user login (Status: \(httpResponse.statusCode))",
                    details: "This endpoint needs Authorization Code Flow, not Client Credentials. Error: \(errorString)"
                ))
            }
        } catch {
            await addResult(TestResult(
                name: "Top Tracks",
                status: .failure,
                message: "Request failed",
                details: error.localizedDescription
            ))
        }
    }

    @MainActor
    private func addResult(_ result: TestResult) {
        testResults.append(result)
    }
}

// MARK: - Test Result Model
struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let status: TestStatus
    let message: String
    let details: String

    enum TestStatus {
        case success
        case failure
    }
}

// MARK: - Test Result Card
struct TestResultCard: View {
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: result.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.status == .success ? .green : .red)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 3) {
                    Text(result.name)
                        .font(.custom("Rokkitt-Regular", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(result.message)
                        .font(.custom("Rokkitt-Regular", size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if !result.details.isEmpty {
                Text(result.details)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    SpotifyTestView()
}
