# Exhale

A voice venting app that lets you speak your mind and let it go. This Flutter application provides a simple, elegant interface for recording your thoughts, playing them back once, and then watching them disappear in a satisfying animation.

## Features

- **Simple Single-Screen UI**: Dark theme with a prominent purple microphone button
- **Press-and-Hold Recording**: Intuitive gesture to start and stop recording
- **Auto-Playback**: Automatically plays your recording once when you release the button
- **Self-Destructing Recordings**: Recordings are deleted immediately after playback
- **Satisfying Animations**: Button pulse effect and a "poof" animation when your recording vanishes

## Getting Started

### Prerequisites

- Flutter SDK (latest version recommended)
- Android Studio / Xcode for mobile deployment
- Physical device recommended for testing audio features

### Installation

1. Clone this repository
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Run the app:
   ```
   flutter run
   ```

## Testing

### On a Physical Device

1. Connect your device via USB and enable USB debugging
2. Run the app with:
   ```
   flutter run
   ```
3. Grant microphone permissions when prompted
4. Press and hold the purple mic button to start recording
5. Release to stop recording and hear your playback
6. Watch your recording disappear with the "poof" animation

### On a Browser

1. Run the app with:
   ```
   flutter run -d chrome
   ```
2. Note: Browser testing may have limited audio functionality due to browser security restrictions. For the best experience, test on a physical device.

## Permissions

The app requires microphone permission which is requested at runtime using the `permission_handler` package.

## Technical Details

- **Audio Handling**: Uses `flutter_sound` for recording and playback
- **Animations**: Combines `AnimatedContainer` for button scaling and Lottie for the "poof" effect
- **File Management**: Temporary recordings stored in the device's temp directory and deleted after playback
