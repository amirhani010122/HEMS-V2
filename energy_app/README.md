# 🔋 EnergyIQ - IoT Energy Monitoring Platform

A professional-grade Flutter mobile application for real-time energy consumption monitoring, device management, and AI-powered insights. Built with enterprise-level architecture and Material 3 design system.

## 📱 Features

### Core Features
- **🔐 Authentication**: Secure login/registration with token management
- **📊 Dashboard**: Comprehensive energy overview with KPIs and alerts
- **🔌 Device Management**: Add, monitor, and manage IoT devices
- **📈 Consumption Analytics**: Daily, monthly, and per-device consumption charts
- **⚡ Plan Management**: Subscribe to energy plans with quota tracking
- **🚨 Alerts System**: Real-time alerts for consumption thresholds
- **🤖 AI Insights**: Machine learning-powered consumption analysis and predictions
- **👤 User Profile**: Account management and settings

### Technical Features
- **Clean Architecture**: Repository pattern with clear separation of concerns
- **Riverpod State Management**: Reactive and type-safe state management
- **Material 3 Design**: Modern dark theme with responsive layouts
- **Secure Storage**: Encrypted token and sensitive data storage
- **Error Handling**: Comprehensive error handling and user feedback
- **Loading States**: Skeleton loaders and smooth transitions
- **Offline Support**: Graceful handling of network failures
- **Pull-to-Refresh**: Updated data with refresh indicators

## 🏗️ Architecture

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── config/
│   │   └── api_config.dart           # API endpoints & configuration
│   ├── network/
│   │   ├── dio_client.dart           # HTTP client with interceptors
│   │   └── auth_interceptor.dart     # JWT token injection
│   ├── storage/
│   │   └── secure_storage.dart       # Encrypted token storage
│   ├── error/
│   │   ├── app_exception.dart        # Custom exception classes
│   │   └── error_handler.dart        # Error parsing & mapping
│   └── theme/
│       └── app_theme.dart            # Material 3 dark theme
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_api.dart         # Login/register API calls
│   │   │   └── auth_repository.dart  # Business logic
│   │   ├── logic/
│   │   │   └── auth_provider.dart    # Riverpod state
│   │   └── ui/
│   │       ├── login_page.dart       # Login screen
│   │       └── register_page.dart    # Registration screen
│   │
│   ├── dashboard/
│   │   └── ui/
│   │       └── dashboard_page.dart   # Main dashboard
│   │
│   ├── devices/
│   │   ├── data/
│   │   │   ├── devices_api.dart
│   │   │   └── devices_repository.dart
│   │   ├── logic/
│   │   │   └── devices_provider.dart
│   │   └── ui/
│   │       ├── devices_page.dart     # Devices list
│   │       └── device_detail_page.dart
│   │
│   ├── consumption/
│   │   ├── data/
│   │   │   └── consumption_api.dart
│   │   ├── logic/
│   │   │   └── consumption_provider.dart
│   │   └── ui/
│   │       └── consumption_page.dart # Analytics with charts
│   │
│   ├── plans/
│   │   ├── data/
│   │   │   └── plans_api.dart
│   │   ├── logic/
│   │   │   └── plans_provider.dart
│   │   └── ui/
│   │       └── plans_page.dart
│   │
│   ├── alerts/
│   │   ├── data/
│   │   │   └── alerts_api.dart
│   │   └── ui/
│   │       └── alerts_page.dart
│   │
│   ├── ai/
│   │   ├── data/
│   │   │   └── ai_api.dart
│   │   └── ui/
│   │       └── ai_insights_page.dart
│   │
│   └── profile/
│       ├── data/
│       │   └── profile_api.dart
│       ├── logic/
│       │   └── profile_provider.dart
│       └── ui/
│           └── profile_page.dart
│
├── shared/
│   ├── models/                       # Freezed data classes
│   │   ├── user_model.dart
│   │   ├── device_model.dart
│   │   ├── consumption_model.dart
│   │   ├── plan_model.dart
│   │   ├── alert_model.dart
│   │   └── ai_model.dart
│   └── widgets/                      # Reusable UI components
│       ├── skeleton_loader.dart      # Shimmer loading
│       ├── app_error_widget.dart     # Error display
│       ├── stat_card.dart            # KPI cards
│       ├── app_drawer.dart           # Navigation drawer
│       └── empty_state_widget.dart   # Empty states
│
└── routes/
    └── app_router.dart               # GoRouter navigation
```

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.16+** - UI framework
- **Dart 3.2+** - Programming language
- **Material 3** - Design system

### State Management
- **flutter_riverpod** - Reactive state management
- **riverpod_annotation** - Code generation

### Networking
- **dio** - HTTP client
- **pretty_dio_logger** - Request logging

### Storage
- **flutter_secure_storage** - Encrypted storage

### Data Models
- **freezed_annotation** - Immutable data classes
- **json_serializable** - JSON serialization

### UI/UX
- **fl_chart** - Charts and graphs
- **shimmer** - Loading animations
- **cached_network_image** - Image caching
- **percent_indicator** - Progress indicators
- **flutter_svg** - SVG rendering

### Routing
- **go_router** - Navigation management

## 🚀 Getting Started

### Prerequisites
- Flutter 3.16+
- Dart 3.2+
- Android Studio or Xcode
- A running FastAPI backend

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/energy_app.git
   cd energy_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Update API configuration**
   Edit `lib/core/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'https://your-api-domain.com/api/v1';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📡 API Integration

The app connects to a FastAPI backend with the following endpoints:

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login

### Users
- `GET /users/me` - Get current user

### Devices
- `GET /devices` - List all devices
- `POST /devices` - Create device
- `GET /devices/{id}` - Get device details
- `DELETE /devices/{id}` - Delete device

### Consumption
- `POST /consumption` - Record consumption
- `GET /consumption/daily` - Daily consumption
- `GET /consumption/monthly` - Monthly consumption
- `GET /consumption/summary` - Consumption summary
- `GET /consumption/per-device-daily` - Per-device daily data

### Plans
- `GET /plans/available` - Available plans
- `POST /plans/subscribe` - Subscribe to plan
- `GET /plans/subscription` - Current subscription

### Alerts
- `GET /alerts` - Get all alerts

### AI
- `GET /ai/analysis` - Consumption analysis
- `GET /ai/prediction` - Usage prediction
- `GET /ai/plan-exhaustion` - Plan exhaustion forecast
- `GET /ai/recommendations` - Energy saving recommendations

## 🎨 Design System

### Colors
- **Primary (Teal)**: `#00D4AA` - Main actions and highlights
- **Secondary (Purple)**: `#6C63FF` - Secondary elements
- **Accent (Orange)**: `#FF6B35` - Alerts and warnings
- **Success (Green)**: `#4CAF50` - Positive states
- **Warning (Yellow)**: `#FFB300` - Caution states
- **Error (Red)**: `#EF5350` - Error states

### Typography
- **H1**: 28px, bold, letter spacing -0.5
- **H2**: 22px, bold, letter spacing -0.3
- **H3**: 18px, semibold
- **H4**: 15px, semibold
- **Body**: 14px, regular
- **Caption**: 12px, regular, secondary color

## 🔒 Security

- **Token Management**: JWT tokens stored in encrypted secure storage
- **Auth Interceptor**: Automatic token injection in requests
- **Error Handling**: 401 responses trigger logout
- **Secure Storage**: Flutter secure storage with platform-specific encryption

## 📊 State Management Flow

```
UI Widget
  ↓
Riverpod Provider watches state
  ↓
AsyncNotifier or FutureProvider
  ↓
Repository layer
  ↓
API Client (Dio)
  ↓
FastAPI Backend
```

## 🧪 Testing

Build runner for code generation:
```bash
flutter pub run build_runner build
```

## 📦 Building

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📝 Code Generation

The project uses code generation for:

- **Freezed**: Immutable data classes
- **JSON Serializable**: JSON mapping
- **Riverpod Generator**: Provider generation

Run build runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode:
```bash
flutter pub run build_runner watch
```

## 🐛 Common Issues

### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Network Issues
Check `api_config.dart` for correct base URL and ensure backend is running.

### Secure Storage Issues
- iOS: Run `pod install` in ios directory
- Android: Ensure Android Keystore is available

## 📚 Project Structure Best Practices

1. **Feature-based structure**: Each feature is self-contained
2. **Separation of concerns**: Data, logic, and UI layers
3. **Type safety**: Strong typing with Dart
4. **Error handling**: Comprehensive exception handling
5. **Immutability**: Using Freezed for data classes
6. **Reactive**: Riverpod for state management

## 🚀 Future Enhancements

- [ ] Offline sync
- [ ] Push notifications
- [ ] Dark/Light theme toggle
- [ ] Multi-language support
- [ ] Export data to CSV/PDF
- [ ] Device scheduling
- [ ] Energy comparison with peers
- [ ] Detailed analytics reports

## 📄 License

This project is proprietary and confidential.

## 👨‍💼 Support

For issues and questions, please contact the development team.

---

**Built with ❤️ using Flutter**
