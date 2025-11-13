//
//  SwipeableCardStackView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

struct SwipeableCardStackView: View {
    @ObservedObject var viewModel: SongViewModel
    @StateObject private var authManager = SpotifyAuthManager.shared
    @StateObject private var audioManager = AudioPlayerManager.shared
    @State private var showNextCard = false
    @State private var showTestView = false
    @State private var showFilterView = false

    var body: some View {
        ZStack {
            backgroundWithFades

            VStack (alignment: .center){
                header

                Spacer()

                ZStack {
                    if viewModel.isLoading && viewModel.songs.isEmpty {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage, viewModel.songs.isEmpty {
                        errorView(message: errorMessage)
                    } else {
                        cardStack
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Dynamic background

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

    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SoundSwipe")
                        .font(.custom("Rokkitt-Regular", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if let userName = authManager.userDisplayName {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 12))
                            Text("Hi, \(userName)")
                                .font(.custom("Rokkitt-Regular", size: 14))
                        }
                        .foregroundColor(.green)
                    }
                }
                .layoutPriority(1)
                
                Spacer().frame(maxWidth: 85)

                // Filter Button
                Button(action: {
                    showFilterView = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.musicFilter.isActive ? .green : .white)
                }
                .sheet(isPresented: $showFilterView) {
                    FilterView(filter: $viewModel.musicFilter)
                        .onDisappear {
                            // Reload recommendations when filter changes
                            Task {
                                await viewModel.loadPersonalizedRecommendations()
                            }
                        }
                }

                // Refresh Button
                Button(action: {
                    Task {
                        await viewModel.loadPersonalizedRecommendations()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                // Test API Button (optional - can be removed in production)
                Button(action: {
                    showTestView = true
                }) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
                .sheet(isPresented: $showTestView) {
                    SpotifyTestView()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Card Stack
    private var cardStack: some View {
        ZStack {
            // Current card
            if let currentSong = viewModel.currentSong {
                SwipeableSongCardView(
                    song: currentSong,
                    onSwipe: { direction in
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.handleSwipe(direction: direction)
                        }
                    }, audioManager: audioManager
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .id(currentSong.id)
            } else if !viewModel.isLoading {
                noMoreSongsView
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading recommendations...")
                .font(.custom("Rokkitt-Regular", size: 18))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text(message)
                .font(.custom("Rokkitt-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                Task {
                    await viewModel.authenticateAndLoadRecommendations()
                }
            }) {
                Text("Retry")
                    .font(.custom("Rokkitt-Regular", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
    }

    // MARK: - No More Songs View
    private var noMoreSongsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))

            Text("No more songs")
                .font(.custom("Rokkitt-Regular", size: 22))
                .foregroundColor(.white)

            Text("Loading more recommendations...")
                .font(.custom("Rokkitt-Regular", size: 16))
                .foregroundColor(.white.opacity(0.7))

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 10)
            }
        }
    }
}

#Preview {
    SwipeableCardStackView(viewModel: SongViewModel())
}
