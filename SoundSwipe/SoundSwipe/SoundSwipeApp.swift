//
//  SoundSwipeApp.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 10/29/25.
//

import SwiftUI

@main
struct SoundSwipeApp: App {
    @StateObject private var authManager = SpotifyAuthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle Spotify OAuth callback
                    if url.scheme == "soundswipe" {
                        Task {
                            await authManager.handleCallback(url: url)
                        }
                    }
                }
        }
    }
}
