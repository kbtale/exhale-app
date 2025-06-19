# Exhale

A minimalist voice recording application designed for emotional release and mindfulness. Exhale provides a simple interface for recording personal thoughts, playing them back once, and then automatically discarding them.

## Purpose

Exhale serves as a digital space for verbal expression without permanent storage. Users can voice their thoughts, concerns, or emotions, listen to their recording once, and then watch it disappear. This approach encourages the therapeutic act of verbal expression while maintaining complete privacy.

## Current Status

**Release Version: 1.1.0**

The application is currently in release and available for download. All core functionality has been implemented and tested across multiple platforms.

## Features

### Audio Recording
- High-quality voice recording using advanced audio codecs
- Visual feedback during recording with button state changes
- Tap-to-start, tap-to-stop recording interface

### Playback Visualization
- Real-time wave animation during audio playback
- Progress tracking with 8 animated bars that fill as audio plays
- Playback controls including pause, resume, and stop functionality

### User Interface
- Single-screen design with consistent element positioning
- No layout shifts during state changes
- Smooth fade transitions between interface states
- Dark theme with purple accent colors
- Responsive design across different screen sizes

### Privacy and Security
- Temporary file storage only
- Automatic deletion of recordings after playback
- No data transmission or cloud storage
- Local audio processing

### Multilingual Support
- Full localization in 13 languages
- Automatic language detection based on system settings
- Support for English, Spanish, French, German, Italian, Portuguese, Japanese, Chinese, Russian, Arabic, Korean, Dutch, and Swedish

### Platform Compatibility
- Native Android application with APK distribution
- iOS compatibility
- Web browser support with visual-only mode
- Desktop support for Windows, macOS, and Linux

## Download

### Android APK
The latest release (v1.1.0) is available for download:

- [Download from GitHub Releases](https://github.com/kbtale/exhale-app/releases/latest)
- File size: approximately 40MB
- Minimum Android version: 5.0 (API 21)

## Installation and Usage

### For End Users
1. Download the APK file from the GitHub releases page
2. Install the application on your Android device
3. Grant microphone permissions when prompted
4. Tap the microphone button to begin recording
5. Tap again to stop recording
6. Use the playback controls to listen to your recording
7. The recording is automatically deleted when playback ends

### For Developers
```bash
# Clone the repository
git clone https://github.com/kbtale/exhale-app.git
cd exhale-app

# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Build release APK
flutter build apk --release
```

## Technical Implementation

### Audio Processing
- **flutter_sound**: Professional-grade audio recording and playback
- **permission_handler**: Runtime permission management
- AAC audio codec for optimal quality and compression

### User Interface
- **Material Design 3**: Modern Flutter UI components
- **Custom animations**: Sine wave calculations for audio visualization
- **Fixed layout system**: Prevents interface shifting during state changes
- **AnimatedOpacity**: Smooth element transitions

### File Management
- **path_provider**: Cross-platform temporary file access
- Platform-specific implementations for web and mobile environments
- Automatic cleanup of temporary audio files

### Internationalization
- **flutter_localizations**: Built-in Flutter internationalization
- ARB (Application Resource Bundle) files for all supported languages
- Automatic locale detection and switching

## Architecture

```
lib/
├── main.dart           # Application logic and user interface
├── file_utils.dart     # Cross-platform file operations
├── web_file_utils.dart # Web-specific file handling
└── l10n/              # Localization resources
    ├── app_en.arb     # English translations
    ├── app_es.arb     # Spanish translations
    └── [other languages]
```

## Development Requirements

- Flutter SDK 3.0 or higher
- Android Studio or Xcode for mobile development
- Physical device recommended for audio testing
- Microphone permissions for full functionality

## License

This project is open source and available under the MIT License.

## Repository

Source code and releases are maintained at: https://github.com/kbtale/exhale-app
