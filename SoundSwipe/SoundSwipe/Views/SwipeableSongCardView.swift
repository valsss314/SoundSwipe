//
//  SwipeableSongCardView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/12/25.
//

import SwiftUI

enum SwipeDirection {
    case left
    case right
}

struct SwipeableSongCardView: View {
    let song: Song
    var albumArtwork: Image?
    var onSwipe: ((SwipeDirection) -> Void)?

    @State private var offset: CGSize = .zero
    @State private var isRemoved: Bool = false

    private let swipeThreshold: CGFloat = 100
    private let rotationAngle: Double = 10

    var body: some View {
        ZStack {
            if !isRemoved {
                VStack(spacing: 0) {
                    cardContent
                        .offset(offset)
                        .rotationEffect(.degrees(Double(offset.width / 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                }
                                .onEnded { gesture in
                                    handleSwipeEnd(gesture: gesture)
                                }
                        )

                    actionButtons
                        .padding(.top, 30)
                }
            }
        }
    }

    private var cardContent: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 24) {
                ZStack {
                    if let artwork = albumArtwork {
                        artwork
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    } else if let artworkURL = song.albumArtworkURL, let url = URL(string: artworkURL) {
                        // Load from URL
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                placeholderArtwork
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 300, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                            case .failure:
                                placeholderArtwork
                            @unknown default:
                                placeholderArtwork
                            }
                        }
                    } else {
                        placeholderArtwork
                    }
                }
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                VStack(spacing: 12) {
                    Text(song.name)
                        .font(.custom("Rokkitt-Regular", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 20)

                    Text(song.artist)
                        .font(.custom("Rokkitt-Regular", size: 22))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)

                    Text(song.album)
                        .font(.custom("Rokkitt-Regular", size: 18))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .padding(30)

            // Swipe indicators
            if abs(offset.width) > 50 {
                swipeIndicator
            }
        }
        .frame(width: 350, height: 550)
    }

    private var swipeIndicator: some View {
        VStack {
            HStack {
                if offset.width > 50 {
                    // Like indicator
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .opacity(Double(offset.width / 100))
                        .padding(.leading, 40)
                    Spacer()
                } else if offset.width < -50 {
                    // Dislike indicator
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.red)
                        .opacity(Double(-offset.width / 100))
                        .padding(.trailing, 40)
                }
            }
            Spacer()
        }
        .padding(.top, 60)
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.8),
                        Color.blue.opacity(0.8),
                        Color.pink.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 300, height: 300)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
            )
    }

    private var actionButtons: some View {
        HStack(spacing: 60) {
            // Dislike button (X)
            Button(action: {
                swipeLeft()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.red)
                }
            }

            // Like button (Heart)
            Button(action: {
                swipeRight()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                }
            }
        }
    }

    private func handleSwipeEnd(gesture: DragGesture.Value) {
        let horizontalSwipe = gesture.translation.width

        if horizontalSwipe > swipeThreshold {
            // Swipe right (like)
            swipeRight()
        } else if horizontalSwipe < -swipeThreshold {
            // Swipe left (dislike)
            swipeLeft()
        } else {
            // Return to center
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                offset = .zero
            }
        }
    }

    private func swipeLeft() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            offset = CGSize(width: -500, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isRemoved = true
            onSwipe?(.left)
        }
    }

    private func swipeRight() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            offset = CGSize(width: 500, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isRemoved = true
            onSwipe?(.right)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        SwipeableSongCardView(
            song: Song(
                name: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera"
            ),
            onSwipe: { direction in
                print("Swiped \(direction)")
            }
        )
    }
}
