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
        ZStack {
            if authManager.isAuthenticated {
                // Show main app with tab navigation
                MainTabView()
            } else {
                // Show login view
                SpotifyLoginView()
            }
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            if newValue {
                print("✅ User authenticated, showing main app")
            }
        }
    }
}

#Preview {
    ContentView()
}
