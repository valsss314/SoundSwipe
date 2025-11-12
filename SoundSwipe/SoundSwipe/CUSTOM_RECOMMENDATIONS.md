# Custom Recommendation Engine

## Why Custom?

The Spotify Recommendations API endpoint (`/v1/recommendations`) has limitations and may be deprecated. Instead, we built a **custom recommendation engine** that uses your actual listening data and Spotify's search API to find great music!

## How It Works

### 🎯 Four Smart Strategies

The engine uses **4 different strategies** to find music you'll love:

#### **1. Top Artists Strategy** 📊
- Gets your top 5 favorite artists from Spotify
- Searches for more songs by these artists
- **Example**: If you love Taylor Swift, it finds more Taylor Swift songs

#### **2. Similar Artists Strategy** 🔍
- Analyzes your top tracks to find artist names
- Searches for "similar to [artist]" and "like [artist]"
- **Example**: If you like Arctic Monkeys, it searches for "similar to Arctic Monkeys"

#### **3. Genre-Based Strategy** 🎸
- Gets genres from your favorite artists
- Searches for popular tracks in those genres
- Includes recent releases (2023-2024)
- **Example**: If your artists are indie/alternative, it finds more indie tracks

#### **4. Trending Keywords Strategy** 🔥
- Analyzes your favorite track names for common words
- Searches for trending songs with similar themes
- **Example**: If you like songs with "love" or "night", finds similar themed songs

### 🧠 Smart Features

**Deduplication**
- Tracks every song you've seen
- Never shows the same song twice
- Filters out duplicates from different searches

**Mixing & Shuffling**
- Combines results from all 4 strategies
- Shuffles for variety
- Ensures you get a good mix

**Fallback**
- If not logged in → uses generic popular music
- If any strategy fails → continues with others
- Always finds music!

## What Makes It Personalized?

### With Spotify Login ✅
- Uses YOUR top artists
- Uses YOUR top tracks
- Uses YOUR favorite genres
- Based on YOUR listening history
- **Result**: Truly personalized to your taste!

### Without Login ⚠️
- Uses generic popular genres
- Searches trending tracks
- Still good music, just not personalized

## Technical Details

### API Calls Per Recommendation Load:
- 1 call: Get your top artists
- 1 call: Get your top tracks
- 3-5 calls: Get artist details (names & genres)
- 10-15 calls: Search queries for tracks
- **Total**: ~20-25 API calls per load

### Caching:
- Artist names cached
- Artist genres cached
- Reduces repeated API calls

### Performance:
- Runs all strategies in parallel when possible
- Continues even if some strategies fail
- Typically takes 2-3 seconds

## Recommendation Quality

### Factors Affecting Quality:

**Better Recommendations If:**
- ✅ You're logged in
- ✅ You have listening history on Spotify
- ✅ You've listened to diverse artists
- ✅ Your top artists have clear genres

**Worse Recommendations If:**
- ❌ New Spotify account
- ❌ Limited listening history
- ❌ Very niche/obscure artists
- ❌ Not logged in

## Customization

Want to tweak the algorithm? Here's where:

### Change Strategy Weights
In `CustomRecommendationEngine.swift`:
```swift
// Current distribution (out of 20 tracks):
- Top Artists: limit/2 = 10 tracks
- Similar Artists: limit/3 = 6-7 tracks
- Genres: limit/3 = 6-7 tracks
- Trending: limit/4 = 5 tracks
```

### Add New Strategies

Add a new function like:
```swift
private func getTracksFromNewStrategy(limit: Int) async throws -> [SpotifyTrack] {
    // Your search logic here
    return tracks
}
```

Then call it in `getPersonalizedRecommendations()`.

### Change Search Queries

Modify the search strings:
```swift
// Current:
"artist:\(artistName)"
"genre:\(genre) year:2024"
"\(artistName) similar"

// You could add:
"mood:\(mood)"
"tempo:\(tempo)"
etc.
```

## Debugging

Enable detailed logs by checking console output:

```
🎵 Starting custom recommendation engine...
📊 Strategy 1: Top Artists
   ✅ Got 10 tracks from top artists
📊 Strategy 2: Similar Artists
   ✅ Got 7 tracks from similar artists
📊 Strategy 3: Genre-based
   🎸 User's favorite genres: indie, alternative, rock
   ✅ Got 6 tracks from genres
📊 Strategy 4: Trending in your genres
   ✅ Got 5 trending tracks
✅ Custom recommendation engine completed: 20 tracks
```

## Comparison vs Spotify Recommendations API

| Feature | Spotify API | Custom Engine |
|---------|-------------|---------------|
| Requires login | ❌ No | ✅ Yes (better with) |
| Uses listening history | ✅ Yes | ✅ Yes |
| Deduplication | ❌ No | ✅ Yes |
| Variety control | ❌ Limited | ✅ High |
| Fallback options | ❌ No | ✅ Multiple |
| Customizable | ❌ No | ✅ Fully |
| Genre mixing | ⚠️ Limited | ✅ Advanced |
| Artist discovery | ⚠️ Sometimes | ✅ Built-in |

## Future Improvements

Potential enhancements:

1. **Collaborative Filtering**: Use liked songs to improve recommendations
2. **Mood Detection**: Analyze track features (tempo, energy, valence)
3. **Time-based**: Different music for morning/evening
4. **Weather-based**: Use weather API for mood-appropriate music
5. **Social**: Recommendations from friends
6. **Machine Learning**: Learn from swipe patterns
7. **Audio Features**: Use Spotify's audio analysis API

## Performance Metrics

Track these in console:
- Songs discovered: `viewModel.getRecommendationStats()`
- Seen tracks count: `recommendationEngine.getSeenTrackCount()`
- Success rate of each strategy (logged)

## Troubleshooting

### "No recommendations loading"
- Check you're logged in to Spotify
- Verify internet connection
- Check console for specific errors

### "Getting same songs repeatedly"
- Shouldn't happen! Check deduplication is working
- Try `viewModel.clearRecommendationHistory()`

### "All recommendations are generic"
- You might not be logged in
- Or your Spotify account is new
- Build listening history by using Spotify more

### "Too slow"
- Reduce number of strategies
- Reduce tracks per strategy
- Add more caching

## Code Location

**Main Files:**
- `Services/CustomRecommendationEngine.swift` - Core algorithm
- `ViewModels/SongViewModel.swift` - Integration
- `Services/SpotifyService.swift` - API calls

**Key Functions:**
- `getPersonalizedRecommendations()` - Main entry point
- `filterAndDeduplicate()` - Prevents duplicates
- `markTrackAsSeen()` - Tracks history

## Summary

The custom recommendation engine gives you **truly personalized music discovery** based on your actual Spotify listening habits, with smart deduplication and multiple fallback strategies to always find great music! 🎵

It's more flexible, customizable, and reliable than using Spotify's deprecated recommendations API alone.
