# 🚀 Setup & Development Guide

## Prerequisites

### System Requirements
- **Flutter**: 3.16.0 or higher
- **Dart**: 3.2.0 or higher
- **Java**: JDK 11+
- **Android SDK**: API 21+
- **Xcode**: 14.0+ (for iOS)

### Tools Installation

#### macOS
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Flutter
brew install flutter

# Install Android SDK
brew install --cask android-studio

# Install Xcode (from App Store or)
xcode-select --install
```

#### Windows
```bash
# Using chocolatey
choco install flutter dart jdk11

# Or download manually from:
# https://flutter.dev/docs/get-started/install/windows
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y flutter dart openjdk-11-jdk

# Or use Flutter's installation guide:
# https://flutter.dev/docs/get-started/install/linux
```

## Project Setup

### 1. Clone Repository
```bash
git clone https://github.com/energyiq/flutter-app.git
cd energy_app
```

### 2. Install Dependencies
```bash
# Install Dart packages
flutter pub get

# Upgrade packages to latest
flutter pub upgrade

# Get packages in example (if any)
cd example
flutter pub get
cd ..
```

### 3. Code Generation
```bash
# Generate models, APIs, and other generated code
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch for changes
flutter pub run build_runner watch
```

### 4. Environment Configuration

Edit `lib/core/config/environment.dart`:
```dart
static const Environment _currentEnvironment = Environment.development;

// For different environments:
// Environment.development   → http://localhost:8000/api/v1
// Environment.staging       → https://staging-api.energyiq.com/api/v1
// Environment.production    → https://api.energyiq.com/api/v1
```

Edit `lib/core/config/api_config.dart` if base URL differs:
```dart
static const String baseUrl = 'https://your-api-domain.com/api/v1';
```

### 5. Platform-Specific Setup

#### Android Setup
```bash
# Enter Android directory
cd android

# Download Android SDK (if needed)
./gradlew downloadSdks

# Back to root
cd ..

# Run on Android emulator or device
flutter run -d emulator-5554
```

#### iOS Setup
```bash
# Enter iOS directory
cd ios

# Install pods
pod install

# Back to root
cd ..

# Run on iOS simulator
flutter run -d all
```

## Running the App

### Development
```bash
# Run on default device
flutter run

# Run on specific device
flutter run -d device_id

# Run with verbose output
flutter run -v

# Run in release mode
flutter run --release

# Hot reload
press 'r' in terminal
# Hot restart
press 'R' in terminal
```

### Available Devices
```bash
# List all connected devices
flutter devices

# Run on all devices
flutter run -d all
```

## Building

### Android Build

#### Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK
```bash
# First, create keystore (one time)
keytool -genkey -v -keystore ~/key.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 -alias key

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (for Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS Build

```bash
# Build for iOS
flutter build ios --release

# Build and open in Xcode for signing
flutter build ios --release
open ios/Runner.xcworkspace
```

## Code Quality

### Analyze Code
```bash
# Check for linting issues
flutter analyze

# With verbose output
flutter analyze --verbose
```

### Format Code
```bash
# Format all Dart files
dart format lib/ test/

# Format specific file
dart format lib/main.dart
```

### Run Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test
flutter test test/features/auth/auth_test.dart
```

## Debugging

### Debug Mode
```bash
# Run with debug prints enabled
flutter run

# In terminal:
# 'w' - toggle widget tree inspector
# 'p' - show performance overlay
# 't' - show texture layer tree
# 'd' - detach debugger
# 'q' - quit
```

### DevTools
```bash
# Open DevTools
flutter pub global activate devtools
devtools

# Or start with app
flutter run --devtools
```

### Debug Console
```dart
// Use print for simple debugging
print('Debug message: $value');

// Use AppLogger for structured logging
AppLogger.debug('Message', error, stackTrace);
AppLogger.info('Information');
AppLogger.warning('Warning');
AppLogger.error('Error');
AppLogger.success('Success');
```

## Troubleshooting

### Common Issues

#### Build Issues
```bash
# Clean build
flutter clean

# Get dependencies again
flutter pub get

# Rebuild runner
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# Nuclear option
rm -rf pubspec.lock
rm -rf .dart_tool
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Network Issues
- Check `API_CONFIG.baseUrl` is correct
- Verify backend is running
- Check network connectivity
- Try with `--enable-web` flag

#### Secure Storage Issues
```bash
# Android: Clear app data
adb shell pm clear com.energyiq.app

# iOS: Uninstall and reinstall
flutter clean
flutter run
```

#### iOS Pod Issues
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

## Git Workflow

### Before Committing
```bash
# Format code
dart format lib/

# Check for issues
flutter analyze

# Run tests
flutter test

# Commit with clear message
git commit -m "feat: add new feature"
```

### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>

Types:
- feat: new feature
- fix: bug fix
- docs: documentation
- style: code style
- refactor: code refactoring
- test: tests
- chore: build/deps/ci
```

## Performance Monitoring

### Frame Rate
In debug console, press 'p' to show performance overlay:
- Green bar: good performance
- Orange bar: acceptable
- Red bar: poor performance

### Memory Usage
```bash
# Monitor memory during app runtime
flutter run --debug
# Press 'm' in terminal to print memory usage
```

### Build Size
```bash
# Analyze APK size
flutter build apk --analyze-size --release

# Analyze app bundle size
flutter build appbundle --analyze-size --release
```

## Documentation

### Generate Dartdoc
```bash
# Generate documentation
dart doc

# View documentation
# Open html/index.html in browser
```

## Dependencies Management

### Update Dependencies
```bash
# Check outdated packages
flutter pub outdated

# Update all packages
flutter pub upgrade

# Update specific package
flutter pub upgrade package_name

# Get specific version
flutter pub add package_name:version
```

### Add/Remove Packages
```bash
# Add package
flutter pub add package_name

# Add dev package
flutter pub add --dev package_name

# Remove package
flutter pub remove package_name
```

## Deployment Checklist

- [ ] All code formatted with `dart format`
- [ ] No linting errors from `flutter analyze`
- [ ] All tests passing
- [ ] Build version updated in `pubspec.yaml`
- [ ] Changelog updated
- [ ] Screenshots updated
- [ ] API endpoints configured for target environment
- [ ] Release notes prepared
- [ ] Testing completed on multiple devices
- [ ] Crash reporting configured (if applicable)
- [ ] Analytics configured (if applicable)

## Useful Links

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Freezed Documentation](https://pub.dev/packages/freezed)

## Support & Issues

For issues and questions:
1. Check existing GitHub issues
2. Search Flutter/Dart documentation
3. Ask in Flutter community (Stack Overflow, Reddit)
4. Open a new GitHub issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Device/OS information
   - Flutter/Dart versions

---

**Happy coding! 🚀**
