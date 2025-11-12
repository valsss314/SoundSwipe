//
//  SpotifyLoginView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

struct SpotifyLoginView: View {
    @StateObject private var authManager = SpotifyAuthManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.11, green: 0.73, blue: 0.33), // Spotify green
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Spotify Logo
                Image(systemName: "music.note.list")
                    .font(.system(size: 100))
                    .foregroundColor(.white)

                VStack(spacing: 15) {
                    Text("SoundSwipe")
                        .font(.custom("Rokkitt-Regular", size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Discover music with a swipe")
                        .font(.custom("Rokkitt-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Login Info
                VStack(spacing: 20) {
                    Text("Connect your Spotify account to get personalized recommendations")
                        .font(.custom("Rokkitt-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Login Button
                    Button(action: {
                        login()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.system(size: 20))

                            Text("Login with Spotify")
                                .font(.custom("Rokkitt-Regular", size: 20))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Color(red: 0.11, green: 0.73, blue: 0.33) // Spotify green
                        )
                        .cornerRadius(30)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)

                    // Test URL Button (debug)
                    Button(action: {
                        testAuthURL()
                    }) {
                        Text("Test Auth URL")
                            .font(.custom("Rokkitt-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // Continue without login
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue without login")
                            .font(.custom("Rokkitt-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .underline()
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .alert("Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func testAuthURL() {
        print("\n" + String(repeating: "=", count: 80))
        print("STING SPOTIFY AUTHORIZATION")
        print(String(repeating: "=", count: 80))

        // Print configuration
        authManager.printConfiguration()

        // First test - can we open a simple Spotify URL?
        let simpleURL = URL(string: "https://accounts.spotify.com")!
        print("\n Test 1: Opening simple Spotify URL...")
        print("   URL: \(simpleURL)")

        UIApplication.shared.open(simpleURL) { success in
            print(success ? "    Simple URL works!" : "    Simple URL failed - Safari may be restricted")
        }

        // Now test our auth URL
        print("\n Test 2: Generating authorization URL...")
        if let url = authManager.getAuthorizationURL() {
            print("    Generated URL successfully!")
            print("\n GENERATED URL:")
            print("   \(url.absoluteString)")
            print("\n URL Analysis:")
            print("   Length: \(url.absoluteString.count) characters")
            print("   Scheme: \(url.scheme ?? "none")")
            print("   Host: \(url.host ?? "none")")
            print("   Path: \(url.path)")

            // Parse query items
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                print("\n Query Parameters:")
                for item in queryItems {
                    let value = item.value ?? "nil"
                    print("   \(item.name): \(value.prefix(50))\(value.count > 50 ? "..." : "")")
                }
                print("    URL components are valid")
            } else {
                print("    URL components are invalid!")
            }

            // Copy to clipboard
            UIPasteboard.general.string = url.absoluteString
            print("\n URL copied to clipboard")

            print(String(repeating: "=", count: 80) + "\n")

            errorMessage = "URL copied to clipboard!\n\nCheck Xcode console for full details."
            showError = true

            // Try to open it
            print(" Attempting to open URL in Safari...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIApplication.shared.open(url) { success in
                    if success {
                        print(" Successfully opened URL in Safari")
                    } else {
                        print(" Failed to open URL in Safari")
                        print("   This could mean:")
                        print("   - URL is malformed")
                        print("   - Safari is restricted")
                        print("   - iOS security policy blocking the URL")
                    }
                }
            }
        } else {
            print("    Failed to generate URL")
            print(String(repeating: "=", count: 80) + "\n")
            errorMessage = "Failed to generate authorization URL"
            showError = true
        }
    }

    private func login() {
        guard let authURL = authManager.getAuthorizationURL() else {
            print(" Failed to generate authorization URL")
            errorMessage = "Failed to generate login URL. Please check your internet connection and try again."
            showError = true
            return
        }

        print("🔐 Opening Spotify login: \(authURL.absoluteString)")

        // Verify URL is valid
        guard authURL.absoluteString.hasPrefix("https://accounts.spotify.com/authorize") else {
            print(" Invalid authorization URL: \(authURL.absoluteString)")
            errorMessage = "Invalid login URL generated. Please contact support."
            showError = true
            return
        }

        UIApplication.shared.open(authURL) { success in
            if !success {
                print(" Failed to open URL in Safari")
                errorMessage = "Could not open Safari. Please make sure Safari is available."
                showError = true
            }
        }
    }
}

#Preview {
    SpotifyLoginView()
}
