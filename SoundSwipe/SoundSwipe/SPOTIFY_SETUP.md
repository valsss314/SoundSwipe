# Spotify API Integration Setup

## Overview
Your SoundSwipe app now integrates with the Spotify API to get song recommendations. After each swipe, the next recommended song automatically appears!

## Setup Instructions

### 1. Get Spotify API Credentials

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account (or create one)
3. Click "Create an App"
4. Fill in the app details:
   - App name: "SoundSwipe"
   - App description: "Music discovery app with swipe interface"
5. Accept the terms and click "Create"
6. You'll see your **Client ID** and **Client Secret** (click "Show Client Secret")

### 2. Add Credentials to Your App

Open `Services/SpotifyService.swift` and replace the placeholder values:

```swift
private let clientId = "YOUR_CLIENT_ID"     // Replace with your actual Client ID
private let clientSecret = "YOUR_CLIENT_SECRET"  // Replace with your actual Client Secret
```

### 3. How It Works

The integration includes:

#### **SpotifyService** (`Services/SpotifyService.swift`)
- Handles authentication with Spotify API
- Fetches song recommendations
- Searches for tracks
- Gets available genre seeds

#### **SongViewModel** (`ViewModels/SongViewModel.swift`)
- Manages the queue of recommended songs
- Handles swipe logic (like/dislike)
- Automatically loads more songs when running low
- Tracks liked and disliked songs
- Can load personalized recommendations based on liked songs

#### **SwipeableCardStackView** (`Views/SwipeableCardStackView.swift`)
- Main view that shows the swipeable cards
- Displays current song and next song preview
- Shows loading states and errors
- Displays statistics (liked/passed counts)

#### **SwipeableSongCardView** (`Views/SwipeableSongCardView.swift`)
- Individual card with swipe gestures
- Loads album artwork from Spotify
- Manual swipe buttons (heart/X)

## Usage

### Basic Usage

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        SwipeableCardStackView()
    }
}
```

### Custom Genre Seeds

```swift
@StateObject var viewModel = SongViewModel()

// Change the seed genres
viewModel.updateSeedGenres(["jazz", "blues", "soul"])
```

### Access Liked Songs

```swift
@StateObject var viewModel = SongViewModel()

// Get all liked songs
let likedSongs = viewModel.likedSongs

// Get all disliked songs
let dislikedSongs = viewModel.dislikedSongs
```

### Load Personalized Recommendations

```swift
// After user has liked some songs, load personalized recommendations
Task {
    await viewModel.loadPersonalizedRecommendations()
}
```

## Features

### Automatic Song Queue Management
- Starts with 20 songs
- Automatically loads more when 5 or fewer songs remain
- Seamless infinite scrolling experience

### Swipe Actions
- **Swipe Right / Heart Button**: Like the song
- **Swipe Left / X Button**: Dislike the song
- Smooth animations and transitions

### Album Artwork
- Automatically downloads from Spotify
- Beautiful gradient placeholder while loading
- Fallback for missing artwork

### Statistics Tracking
- Tracks number of liked songs
- Tracks number of passed songs
- Displays at bottom of screen

## API Endpoints Used

- `POST /api/token` - Authentication (Client Credentials Flow)
- `GET /recommendations` - Get song recommendations
- `GET /search` - Search for tracks
- `GET /recommendations/available-genre-seeds` - Get available genres

## Models

### Song
Updated to support Spotify data:
```swift
struct Song {
    let id: String
    var name: String
    var artist: String
    var album: String
    var albumArtworkURL: String?
    var spotifyURL: String?
    var previewURL: String?
}
```

### SpotifyTrack
Maps Spotify API responses to Song model

## Error Handling

The app handles various errors:
- Authentication failures
- Network errors
- Invalid API responses
- Missing album artwork

Errors are displayed with a retry button in the UI.

## Next Steps

1. Add authentication to save liked songs to Spotify playlists
2. Implement audio preview playback
3. Add more filtering options (mood, tempo, etc.)
4. Social features (share liked songs)
5. Playlist creation from liked songs

## Troubleshooting

**Authentication fails:**
- Check that Client ID and Client Secret are correct
- Ensure your Spotify app is not in development mode restrictions

**No recommendations loading:**
- Check network connection
- Verify API credentials
- Check console for specific error messages

**Album artwork not loading:**
- Check network connection
- Some songs may not have artwork (fallback will show)

## Security Note

**Important:** Never commit your Client ID and Client Secret to version control!
Consider using environment variables or a config file in production.
