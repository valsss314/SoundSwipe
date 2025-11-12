//
//  MainTabView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = SongViewModel()

    var body: some View {
        TabView {
            // Left Tab: Liked Songs
            LikedSongsView(viewModel: viewModel)
                .tabItem {
                    Label("Liked", systemImage: "heart.fill")
                }
                .tag(0)

            // Center Tab: Swipe
            SwipeableCardStackView(viewModel: viewModel)
                .tabItem {
                    Label("Swipe", systemImage: "music.note")
                }
                .tag(1)

            // Right Tab: Profile
            ProfileView(viewModel: viewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(.green)
    }
}

#Preview {
    MainTabView()
}
