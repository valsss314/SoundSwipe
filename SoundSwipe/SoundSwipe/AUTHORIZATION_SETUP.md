# Spotify Authorization Code Flow Setup

## What's New?

You can now **login with your Spotify account** to get truly personalized recommendations based on your listening history! 🎵

## Quick Setup (5 minutes)

### Step 1: Add URL Scheme to Xcode

This allows Spotify to redirect back to your app after login.

**In Xcode:**

1. Select your **SoundSwipe** project in the left sidebar
2. Select the **SoundSwipe** target
3. Click the **Info** tab at the top
4. Scroll down to find **URL Types** section
5. Click the **+** button to add a new URL Type
6. Fill in:
   - **Identifier**: `com.soundswipe.auth`
   - **URL Schemes**: `soundswipe`
   - **Role**: Editor
7. Press **Enter** or **Return** to save

**That's it!** The URL scheme is now configured.

### Step 2: Run the App

1. Build and run the app (Cmd+R)
2. You'll see a **login screen** with Spotify's green color
3. Tap **"Login with Spotify"**
4. Safari will open with Spotify's login page
5. Login with your Spotify account
6. Approve the permissions
7. You'll be redirected back to the app
8. **You're authenticated!** ✅

### Step 3: Verify It's Working

After logging in, you should see:
- Your name in the top-left corner: "Hi, [Your Name]"
- Green checkmark next to your name
- Recommendations based on **your actual listening history**

Tap the 🔧 (wrench) icon to run API tests and verify all endpoints work!

## What You Get with User Login

### ✅ **Personalized Recommendations**
- Based on YOUR top artists
- Based on YOUR top tracks
- Based on YOUR listening history
- Way better than generic genre recommendations!

### ✅ **Access to Your Data**
- Your display name and email
- Your most played artists
- Your most played tracks
- Your playlists (future feature)
- Your saved songs (future feature)

### ✅ **More Features**
All `/me` endpoints now work:
- `/me` - Your profile
- `/me/top/artists` - Your favorite artists
- `/me/top/tracks` - Your favorite songs
- `/me/playlists` - Your playlists
- `/me/tracks` - Your saved songs

## How It Works

### Authorization Code Flow with PKCE

The app uses **Authorization Code Flow with PKCE** (Proof Key for Code Exchange), which is:
- ✅ **Secure** - Industry standard for mobile apps
- ✅ **No client secret needed** - Safe for mobile
- ✅ **Recommended by Spotify** - Best practice

### The Flow:

1. **App** generates a code verifier and challenge
2. **App** opens Spotify login in Safari
3. **User** logs in and approves permissions
4. **Spotify** redirects to `soundswipe://callback?code=...`
5. **App** exchanges code for access token
6. **App** stores access token securely
7. **App** uses token for all API requests

### Token Management:

- **Access Token**: Valid for 1 hour
- **Refresh Token**: Used to get new access tokens
- **Auto-refresh**: Tokens refresh automatically when needed
- **Persistent**: Tokens are saved, so you stay logged in

## Scopes (Permissions)

The app requests these permissions:

| Scope | What it does |
|-------|--------------|
| `user-read-private` | Read your profile info |
| `user-read-email` | Read your email |
| `user-top-read` | Read your top artists/tracks |
| `user-read-recently-played` | Read your recent plays |
| `playlist-read-private` | Read your playlists |
| `playlist-modify-public` | Create/edit public playlists |
| `playlist-modify-private` | Create/edit private playlists |
| `user-library-read` | Read your saved songs |
| `user-library-modify` | Save songs to your library |

## Files Created

### `SpotifyAuthManager.swift`
Handles OAuth flow:
- Generates PKCE codes
- Opens Spotify login
- Exchanges code for token
- Refreshes tokens
- Stores tokens securely

### `SpotifyLoginView.swift`
Beautiful login screen:
- Spotify-themed green gradient
- Login button
- "Continue without login" option

### Updated Files:
- `SoundSwipeApp.swift` - Handles URL callbacks
- `ContentView.swift` - Shows login or main app
- `SpotifyService.swift` - Uses user tokens
- `SongViewModel.swift` - Loads personalized recommendations
- `SwipeableCardStackView.swift` - Shows user name, logout button

## Testing

### Test API Access:

1. Tap the 🔧 (wrench) icon in the top-right
2. Tap **"Run API Tests"**
3. Watch all tests run

**Expected Results (with login):**
- ✅ Authentication
- ✅ Genre Seeds
- ✅ Search
- ✅ Get Track
- ✅ Recommendations
- ✅ New Releases
- ✅ Current User (/me) **← This now works!**
- ✅ Top Artists **← This now works!**
- ✅ Top Tracks **← This now works!**

All 9 tests should pass! 🎉

## Logout

To logout:
- Tap the **logout icon** (🚪) in the top-right corner
- This clears your tokens and returns you to the login screen
- Your data is removed from the app

## Token Storage

Tokens are stored in `UserDefaults`:
- `spotify_access_token`
- `spotify_refresh_token`
- `spotify_token_expiration`

**Security Note**: For production apps, consider using **Keychain** for more secure token storage.

## Troubleshooting

### App doesn't redirect back after login
- Check that URL scheme is set to `soundswipe` (lowercase)
- Make sure Identifier is set
- Try rebuilding the app

### Login fails
- Check that redirect URI in Spotify Dashboard is `soundswipe://callback`
- Verify your Client ID is correct
- Check internet connection

### "/me" endpoints still fail
- Make sure you completed the login flow
- Check the top-left shows your name
- Tap 🔧 to run tests and verify

### Tokens expired
- The app auto-refreshes tokens
- If refresh fails, logout and login again

## Comparison: Before vs After

### Before (Client Credentials):
- ❌ No user data
- ❌ Generic recommendations
- ❌ Can't save songs
- ❌ Can't access playlists
- ❌ No personalization

### After (Authorization Code):
- ✅ Full user data
- ✅ Truly personalized recommendations
- ✅ Can save songs to library
- ✅ Can access/create playlists
- ✅ Based on YOUR music taste!

## Next Steps

Now that you have user authentication, you can:

1. **Save liked songs to a Spotify playlist** 📝
2. **Show user's top tracks in the app** 🎵
3. **Create playlists from swiped songs** 📋
4. **Show recently played tracks** 🕐
5. **Display user's profile picture** 👤
6. **Follow artists you like** ⭐

The possibilities are endless! 🚀

## Need Help?

Check the console logs:
- `✅` = Success
- `❌` = Error
- `🎵` = Music-related
- `🔐` = Authentication

All steps are logged with detailed information!
