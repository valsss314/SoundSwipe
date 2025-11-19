//
//  SongView.swift
//  SoundSwipe
//
//  Created by Jonathan Cheng on 11/5/25.
//

import Foundation
import SwiftUI

// MARK: - Scrolling Text View
struct ScrollingText: View {
    let text: String
    let font: Font
    let color: Color

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    var shouldScroll: Bool {
        textWidth > containerWidth
    }

    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .background(
                    GeometryReader { textGeometry in
                        Color.clear.onAppear {
                            textWidth = textGeometry.size.width
                            containerWidth = geometry.size.width
                        }
                    }
                )
                .offset(x: shouldScroll ? offset : 0)
                .onAppear {
                    if shouldScroll {
                        startScrolling()
                    }
                }
                .onChange(of: text) { _ in
                    offset = 0
                    if shouldScroll {
                        startScrolling()
                    }
                }
        }
        .clipped()
    }

    private func startScrolling() {
        let scrollDistance = textWidth + 20 // Extra space between loops

        withAnimation(
            Animation.linear(duration: Double(scrollDistance / 30))
                .repeatForever(autoreverses: false)
                .delay(1.5)
        ) {
            offset = -scrollDistance
        }
    }
}

struct SongCardView: View {
    let song: Song
    var albumArtwork: Image? = nil

    var body: some View {
        ZStack {
            // Card background with gradient
            GlassCardBackground(cornerRadius: 18)

            HStack(spacing: 12) {
                // Album artwork
                ZStack {
                    // If a preloaded Image is passed in, use it. Otherwise attempt to load from song.albumArtworkURL.
                    if let artwork = albumArtwork {
                        artwork
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 65, height: 65)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if let artworkURL = song.albumArtworkURL,
                              let url = URL(string: artworkURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                // placeholder while loading
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.7),
                                                Color.blue.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 65, height: 65)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white.opacity(0.8))
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 65, height: 65)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            case .failure:
                                // fallback placeholder on failure
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.7),
                                                Color.blue.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 65, height: 65)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white.opacity(0.8))
                                    )
                            @unknown default:
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.7),
                                                Color.blue.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 65, height: 65)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white.opacity(0.8))
                                    )
                            }
                        }
                    } else {
                        // Gradient placeholder
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.7),
                                        Color.blue.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                // Song info
                VStack(alignment: .leading, spacing: 6) {
                    // Song title with scrolling
                    ScrollingText(
                        text: song.name,
                        font: .custom("Rokkitt-Regular", size: 17).weight(.semibold),
                        color: .white
                    )
                    .frame(height: 20)

                    // Artist and album with scrolling
                    VStack(alignment: .leading, spacing: 2) {
                        ScrollingText(
                            text: song.artist,
                            font: .custom("Rokkitt-Regular", size: 14),
                            color: .gray
                        )
                        .frame(height: 16)

                        ScrollingText(
                            text: song.album,
                            font: .custom("Rokkitt-Regular", size: 12),
                            color: .gray.opacity(0.8)
                        )
                        .frame(height: 14)
                    }

                    Spacer()
                }
                

                Spacer()
            }
            .padding(15)
        }
        .frame(height: 90)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}

struct GlassCardBackground: View {
    var cornerRadius: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            // main dark, slightly see-through fill
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.85),
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // frosty blur from whatever is behind
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // glossy outline
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.40),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.25
                    )
                    .blendMode(.screen)
            )
            // soft drop shadow
            .shadow(color: Color.black.opacity(0.7), radius: 24, x: 0, y: 12)
    }
}


#Preview {
    VStack(spacing: 16) {
        SongCardView(
            song: Song(
                name: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera"
            )
        )

        SongCardView(
            song: Song(
                name: "The Great Gig in the Sky (2011 Remastered Version)",
                artist: "Pink Floyd",
                album: "The Dark Side of the Moon"
            )
        )

        SongCardView(
            song: Song(
                name: "Hotel California",
                artist: "Eagles",
                album: "Hotel California (2013 Remaster)"
            )
        )
    }
    .background(Color.black)
}
