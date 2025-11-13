//
//  ContentView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = SpotifyAuthManager.shared
    @State private var showLoginSheet = false

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Main app with tabs
                MainTabView()
            } else {
                // Login screen
                SpotifyLoginView()
            }
        }
        // Just for logging when auth flips
        .onChange(of: authManager.isAuthenticated) { newValue in
            if newValue {
                print("✅ User authenticated, showing main app")
            } else {
                print("🚪 User logged out / token cleared")
            }
        }
    }
}

#Preview {
    ContentView()
}
