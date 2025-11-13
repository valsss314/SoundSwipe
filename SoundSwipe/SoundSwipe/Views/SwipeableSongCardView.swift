import SwiftUI

enum SwipeDirection {
    case left
    case right
}

struct SwipeableSongCardView: View {
    let song: Song
    var albumArtwork: Image?
    var onSwipe: ((SwipeDirection) -> Void)?

    @ObservedObject var audioManager: AudioPlayerManager
    @Environment(\.openURL) private var openURL

    @State private var offset: CGSize = .zero
    @State private var isRemoved: Bool = false

    private let swipeThreshold: CGFloat = 100

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
                        .padding(.top, 10)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Dynamic background

    
    // MARK: - Card content

    private var cardContent: some View {
        ZStack(alignment: .bottomLeading) {
            // Card background
            GlassCardBackground(cornerRadius: 30)

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()

                    ZStack {
                        if let artwork = albumArtwork {
                            artwork
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        } else if let artworkURL = song.albumArtworkURL,
                                  let url = URL(string: artworkURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    placeholderArtwork
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
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
                    .padding(.top, 10)
                    .frame(width: 280, height: 280) // album art size
                    .shadow(color: Color.black.opacity(0.2),
                            radius: 10, x: 0, y: 5)

                    Spacer()
                }

                // Title + artist (still left-aligned)
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.name)
                        .font(.custom("Rokkitt-Regular", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(song.artist)
                        .font(.custom("Rokkitt-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                // Music controls
                musicSection

                Spacer(minLength: 0)
            }
            .padding(24)

            // Album text in bottom-left
            Text(song.album)
                .font(.custom("Rokkitt-Regular", size: 12))
                .foregroundColor(.white.opacity(0.75))
                .padding(.leading, 24)
                .padding(.bottom, 18)

            // Swipe indicator
            if abs(offset.width) > 50 {
                swipeIndicator
            }
        }
        .frame(width: 350, height: 550)
    }


    // MARK: - Music section

    private var musicSection: some View {
        let canPreview = (song.previewURL != nil)
        let isCurrent  = canPreview && audioManager.currentSongID == song.id

        let baseDuration = Double(song.durationMS ?? 0) / 1000
        let durationSec  = isCurrent ? audioManager.duration : baseDuration
        let currentSec   = isCurrent ? audioManager.currentTime : 0

        return VStack(spacing: 8) {
            // Progress bar (only really moves when preview is playing)
            GeometryReader { geo in
                let progress = (durationSec > 0) ? currentSec / max(durationSec, 1) : 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 4)

                    Capsule()
                        .fill(Color.white)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            // Time labels
            HStack {
                Text(formatTime(currentSec))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text(formatTime(durationSec))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Buttons row
            HStack(alignment: .center, spacing: 20) {
                // Back 10s (only makes sense if preview exists)
                Button {
                    if canPreview {
                        if isCurrent {
                            audioManager.seek(by: -10)
                        } else {
                            audioManager.playPreview(for: song)
                            audioManager.seek(by: -10)
                        }
                    }
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(canPreview ? .white : .white.opacity(0.3))
                }
                .disabled(!canPreview)

                // Play / pause OR open Spotify
                Button {
                    if canPreview {
                        audioManager.playPreview(for: song)
                    } else if let urlString = song.spotifyURL,
                              let url = URL(string: urlString) {
                        openURL(url)
                    } else {
                        print("No preview or spotifyURL for \(song.name)")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: canPreview
                              ? (isCurrent && audioManager.isPlaying ? "pause.fill" : "play.fill")
                              : "arrow.up.right.square")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Forward 10s
                Button {
                    if canPreview {
                        if isCurrent {
                            audioManager.seek(by: 10)
                        } else {
                            audioManager.playPreview(for: song)
                            audioManager.seek(by: 10)
                        }
                    }
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(canPreview ? .white : .white.opacity(0.3))
                }
                .disabled(!canPreview)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Optional: tiny “Open in Spotify” text even when preview exists
            if let urlString = song.spotifyURL,
               let url = URL(string: urlString) {
                Button {
                    openURL(url)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11, weight: .medium))
                        Text("Open in Spotify")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Helpers

    private struct GlassCardBackground: View {
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
                .clipShape(RoundedRectangle(cornerRadius: 30))
                // glossy outline
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.40),  // bright at top-left
                                    Color.white.opacity(0.05)   // fades out
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.screen)
                )
                // soft drop shadow
                .shadow(color: Color.black.opacity(0.7), radius: 24, x: 0, y: 12)
        }
    }

    private struct GlassCircleBackground: View {
        var diameter: CGFloat = 70

        var body: some View {
            Circle()
                // dark gradient fill
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
                .clipShape(Circle())
                // glossy outline
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.40),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.screen)
                )
                // soft drop shadow
                .shadow(color: Color.black.opacity(0.7),
                        radius: 24, x: 0, y: 12)
                .frame(width: diameter, height: diameter)
        }
    }

    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private var swipeIndicator: some View {
        VStack {
            HStack {
                if offset.width > 50 {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .opacity(Double(offset.width / 100))
                        .padding(.leading, 40)
                    Spacer()
                } else if offset.width < -50 {
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
        .padding(.top, 40)
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
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
            )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 60) {
            Button(action: {
                swipeLeft()
            }) {
                ZStack {
                    GlassCircleBackground(diameter: 70)

                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.red)
                }
            }

            Button(action: {
                swipeRight()
            }) {
                ZStack {
                    GlassCircleBackground(diameter: 70)

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
            swipeRight()
        } else if horizontalSwipe < -swipeThreshold {
            swipeLeft()
        } else {
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
                album: "A Night at the Opera",
                albumArtworkURL: nil,
                spotifyURL: "https://open.spotify.com/track/whatever",
                previewURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
                durationMS: 354_000
            ),
            onSwipe: { direction in
                print("Swiped \(direction)")
            },
            audioManager: .shared
        )
    }
}
