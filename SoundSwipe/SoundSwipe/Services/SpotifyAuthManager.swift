//
//  SpotifyAuthManager.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import Foundation
import SwiftUI
import CryptoKit

@MainActor
class SpotifyAuthManager: ObservableObject {
    static let shared = SpotifyAuthManager()

    @Published var isAuthenticated = false
    @Published var userAccessToken: String?
    @Published var userDisplayName: String?

    private var refreshToken: String?
    private var tokenExpirationDate: Date?

    private let clientId = "3acdddba753b4ad58671235171d1996b"
    //private let clientId = "9d4c3e338f284a7593908efeee34eee2"
    private let redirectURI = "soundswipe://callback"
    private let scopes = [
        "user-read-private",
        "user-read-email",
        "user-top-read",
        "user-read-recently-played",
        "playlist-read-private",
        "playlist-modify-public",
        "playlist-modify-private",
        "user-library-read",
        "user-library-modify"
    ]

    // For debugging
    func printConfiguration() {
        print(" Configuration:")
        print("   Client ID: \(clientId)")
        print("   Redirect URI: \(redirectURI)")
        print("   Scopes: \(scopes.joined(separator: ", "))")
    }

    private var codeVerifier: String?

    private init() {
        loadStoredTokens()
    }

    // MARK: - Authorization URL
    func getAuthorizationURL() -> URL? {
        // Generate code verifier and challenge for PKCE
        let verifier = generateCodeVerifier()
        self.codeVerifier = verifier

        guard let challenge = generateCodeChallenge(from: verifier) else {
            print(" Failed to generate code challenge")
            return nil
        }

        print(" Generated code verifier: \(verifier.prefix(20))...")
        print(" Generated code challenge: \(challenge.prefix(20))...")

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "show_dialog", value: "true") // Force login screen
        ]

        guard let url = components.url else {
            print(" Failed to create authorization URL")
            return nil
        }

        print(" Authorization URL: \(url.absoluteString)")
        return url
    }

    // MARK: - Handle Callback
    func handleCallback(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print(" Invalid callback URL")
            return
        }

        // Check for error
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            print(" Authorization error: \(error)")
            return
        }

        // Get authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            print(" No authorization code in callback")
            return
        }

        print(" Got authorization code: \(code.prefix(10))...")

        // Exchange code for token
        await exchangeCodeForToken(code: code)
    }

    // MARK: - Exchange Code for Token
    private func exchangeCodeForToken(code: String) async {
        guard let verifier = codeVerifier else {
            print(" No code verifier found")
            return
        }

        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(redirectURI)",
            "client_id=\(clientId)",
            "code_verifier=\(verifier)"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print(" Invalid response type")
                return
            }

            print(" Token exchange response: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print(" Token exchange error: \(errorString)")
                }
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String,
               let expiresIn = json["expires_in"] as? Int {

                self.userAccessToken = accessToken
                self.refreshToken = json["refresh_token"] as? String
                self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                self.isAuthenticated = true

                print(" Successfully authenticated user!")
                print(" Access Token: \(accessToken.prefix(20))...")

                // Save tokens
                saveTokens()

                // Fetch user profile
                await fetchUserProfile()
            }

        } catch {
            print(" Token exchange failed: \(error)")
        }
    }

    // MARK: - Refresh Token
    func refreshAccessToken() async {
        guard let refreshToken = refreshToken else {
            print(" No refresh token available")
            isAuthenticated = false
            return
        }

        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=refresh_token",
            "refresh_token=\(refreshToken)",
            "client_id=\(clientId)"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print(" Failed to refresh token")
                isAuthenticated = false
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String,
               let expiresIn = json["expires_in"] as? Int {

                self.userAccessToken = accessToken
                self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))

                // Update refresh token if provided
                if let newRefreshToken = json["refresh_token"] as? String {
                    self.refreshToken = newRefreshToken
                }

                print(" Token refreshed successfully")
                saveTokens()
            }

        } catch {
            print(" Token refresh failed: \(error)")
            isAuthenticated = false
        }
    }

    // MARK: - Fetch User Profile
    private func fetchUserProfile() async {
        guard let token = userAccessToken else { return }

        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print(" Failed to fetch user profile")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let displayName = json["display_name"] as? String {
                self.userDisplayName = displayName
                print(" User profile: \(displayName)")
            }

        } catch {
            print(" Failed to fetch user profile: \(error)")
        }
    }

    // MARK: - Logout
    func logout() {
        userAccessToken = nil
        refreshToken = nil
        tokenExpirationDate = nil
        userDisplayName = nil
        isAuthenticated = false

        UserDefaults.standard.removeObject(forKey: "spotify_access_token")
        UserDefaults.standard.removeObject(forKey: "spotify_refresh_token")
        UserDefaults.standard.removeObject(forKey: "spotify_token_expiration")

        print(" Logged out")
    }

    // MARK: - Token Storage
    private func saveTokens() {
        if let accessToken = userAccessToken {
            UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")
        }
        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: "spotify_refresh_token")
        }
        if let expirationDate = tokenExpirationDate {
            UserDefaults.standard.set(expirationDate, forKey: "spotify_token_expiration")
        }
    }

    private func loadStoredTokens() {
        userAccessToken = UserDefaults.standard.string(forKey: "spotify_access_token")
        refreshToken = UserDefaults.standard.string(forKey: "spotify_refresh_token")
        tokenExpirationDate = UserDefaults.standard.object(forKey: "spotify_token_expiration") as? Date

        if let expirationDate = tokenExpirationDate, expirationDate > Date() {
            isAuthenticated = true
            Task {
                await fetchUserProfile()
            }
        } else if refreshToken != nil {
            Task {
                await refreshAccessToken()
            }
        }
    }

    // MARK: - PKCE Helpers
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        let base64String = Data(buffer).base64EncodedString()

        // Convert to base64url format (RFC 4648)
        let base64url = base64String
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        print(" Code verifier length: \(base64url.count)")
        return base64url
    }

    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .ascii) else {
            print(" Failed to convert verifier to ASCII data")
            return nil
        }

        let hash = SHA256.hash(data: data)
        let base64String = Data(hash).base64EncodedString()

        let base64url = base64String
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        print(" Code challenge length: \(base64url.count)")
        return base64url
    }
}
