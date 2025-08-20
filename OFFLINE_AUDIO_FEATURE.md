# Offline Audio Feature

## Overview
The Quran app now supports offline audio playback. When users play an audio recitation for the first time, the audio file is automatically downloaded and cached locally for future offline playback.

## Features

### Automatic Audio Caching
- Audio files are automatically downloaded when played for the first time
- Cached files are stored locally in the app's documents directory
- Maximum cache size is limited to 500MB to prevent excessive storage usage
- Oldest files are automatically removed when cache limit is reached

### Offline Playback
- Cached audio files can be played without internet connection
- Visual indicators show which ayahs are available offline
- Download progress is shown during audio caching

### Cache Management
- Users can view cache statistics in Settings > Audio Cache
- Cache can be cleared manually from settings
- Cache usage percentage is displayed with color coding

## Implementation Details

### Files Added/Modified

1. **lib/services/audio_cache_service.dart** - New service for audio caching
   - Handles downloading and storing audio files
   - Manages cache size and cleanup
   - Provides cache statistics

2. **lib/providers/audio_provider.dart** - Enhanced with offline support
   - Integrated with AudioCacheService
   - Added download status tracking
   - Cache management methods

3. **lib/screens/surah_screen.dart** - Updated UI
   - Added offline indicators (green pin icon)
   - Added download buttons for uncached audio
   - Download progress indicators

4. **lib/screens/settings_screen.dart** - Added cache management
   - Audio cache statistics display
   - Cache management dialog
   - Clear cache functionality

5. **pubspec.yaml** - Added dependencies
   - path_provider: ^2.1.2 for file system access

### Key Components

#### AudioCacheService
- Singleton service for managing audio cache
- Automatic cache size management (500MB limit)
- File-based storage with metadata tracking
- Error handling and progress tracking

#### Enhanced AudioProvider
- Seamless integration with cache service
- Automatic download on first play
- Offline playback support
- Cache management methods

#### UI Enhancements
- Visual indicators for cached/uncached audio
- Download progress during caching
- Cache statistics in settings
- User-friendly cache management

## Usage

### For Users
1. **Automatic Caching**: Simply play any audio recitation - it will be cached automatically
2. **Offline Playback**: Once cached, audio can be played without internet
3. **Cache Management**: Go to Settings > Audio Cache to view statistics and manage cache

### For Developers
1. **AudioProvider**: Use existing `playAudio()` method - caching is handled automatically
2. **Cache Management**: Use `getAudioCacheStats()`, `clearAudioCache()` methods
3. **Status Checking**: Use `isAudioCached()` to check if audio is available offline

## Technical Notes

- Cache files are stored in `{app_documents}/audio_cache/`
- File names are derived from the original URL
- Cache metadata is stored in SharedPreferences
- Automatic cleanup removes oldest files when limit is reached
- Error handling ensures graceful fallback to online playback

## Future Enhancements

- Background download queue for multiple files
- Selective cache management (remove specific files)
- Cache compression for storage optimization
- Download progress callbacks for better UX
- Cache sharing between app instances
