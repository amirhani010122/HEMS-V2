# 🏗️ Architecture Documentation

## Overview

EnergyIQ follows a **Clean Architecture** pattern combined with **Repository Pattern** and **Riverpod** for state management. This ensures maintainability, testability, and scalability.

## Architecture Layers

```
┌─────────────────────────────────────┐
│         UI Layer (Widgets)          │
│  (Pages, Screens, Components)       │
├─────────────────────────────────────┤
│    Presentation Layer (State Mgmt)  │
│  (Riverpod Providers, ViewModels)   │
├─────────────────────────────────────┤
│       Domain Layer (Business Logic)  │
│  (Use Cases, Repositories)          │
├─────────────────────────────────────┤
│        Data Layer (API/Storage)      │
│  (API Clients, Local Storage)        │
└─────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer (UI)

**Location**: `lib/features/*/ui/`

Responsible for:
- Displaying UI components
- Handling user interactions
- Showing loading/error states
- Observing state changes via Riverpod

**Example**:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final devicesAsync = ref.watch(devicesProvider);
  
  return devicesAsync.when(
    loading: () => LoadingWidget(),
    error: (e, _) => ErrorWidget(error: e),
    data: (devices) => ListView(children: devices.map(...)),
  );
}
```

### 2. State Management Layer

**Location**: `lib/features/*/logic/`

Responsible for:
- Managing application state
- Handling side effects
- Coordinating between UI and domain layers

**Example**:
```dart
final devicesProvider = AsyncNotifierProvider<DevicesNotifier, List<DeviceModel>>(
  DevicesNotifier.new,
);

class DevicesNotifier extends AsyncNotifier<List<DeviceModel>> {
  @override
  Future<List<DeviceModel>> build() async {
    return ref.watch(devicesRepositoryProvider).getDevices();
  }

  Future<void> addDevice(String id, String name) async {
    // Mutation logic
  }
}
```

### 3. Domain/Business Logic Layer

**Location**: `lib/features/*/data/`

Responsible for:
- Repository pattern implementation
- Business logic coordination
- Data transformation

**Example**:
```dart
class DevicesRepository {
  final DevicesApi _api;

  Future<List<DeviceModel>> getDevices() async {
    try {
      final response = await _api.getDevices();
      return response.map((e) => DeviceModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
```

### 4. Data Layer

**Location**: `lib/core/network/`, `lib/core/storage/`

Responsible for:
- Making API calls
- Local data storage
- Data caching
- Error handling

**Example**:
```dart
class DevicesApi {
  final Dio _dio = DioClient.instance;

  Future<List<DeviceModel>> getDevices() async {
    final response = await _dio.get(ApiConfig.devices);
    return response.data.map((e) => DeviceModel.fromJson(e)).toList();
  }
}
```

## Data Flow

### Typical User Interaction Flow

```
User Taps Button
      ↓
UI Widget calls Provider method
      ↓
StateNotifier (Riverpod) receives call
      ↓
Repository method is invoked
      ↓
API Client makes HTTP request
      ↓
Response received → Error Handling
      ↓
Data transformed to Model
      ↓
State updated in Riverpod
      ↓
UI rebuilds with new state
      ↓
User sees updated UI
```

### Example: Loading Devices

```dart
// 1. UI Layer (Widget)
@override
Widget build(BuildContext context, WidgetRef ref) {
  final devicesAsync = ref.watch(devicesProvider);
  // Auto-fetches via Riverpod
}

// 2. State Management Layer
final devicesProvider = AsyncNotifierProvider<DevicesNotifier, List<DeviceModel>>(
  DevicesNotifier.new,
);

class DevicesNotifier extends AsyncNotifier<List<DeviceModel>> {
  @override
  Future<List<DeviceModel>> build() async {
    // Calls repository
    return ref.watch(devicesRepositoryProvider).getDevices();
  }
}

// 3. Business Logic Layer
class DevicesRepository {
  Future<List<DeviceModel>> getDevices() async {
    // Calls API
    return _api.getDevices();
  }
}

// 4. Data Layer
class DevicesApi {
  Future<List<DeviceModel>> getDevices() async {
    // Makes HTTP request
    final response = await _dio.get(ApiConfig.devices);
    return response.data;
  }
}

// 5. Network Layer
class DioClient {
  static Dio get instance => _createDio();
  // Handles auth, logging, error handling
}
```

## State Management with Riverpod

### AsyncNotifier (for async operations)

```dart
final usersProvider = AsyncNotifierProvider<UserNotifier, UserModel?>(
  UserNotifier.new,
);

class UserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    try {
      return await ref.watch(profileApiProvider).getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await ref.watch(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}
```

### StateNotifier (for sync state)

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      await _repo.login(email, password);
      state = AuthAuthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}
```

### FutureProvider (for simple async reads)

```dart
final dailyConsumptionProvider = FutureProvider<List<DailyConsumption>>((ref) {
  return ref.watch(consumptionApiProvider).getDaily();
});
```

## Error Handling Strategy

### Exception Hierarchy

```
AppException
├── UnauthorizedException (401)
├── NetworkException
├── NotFoundException (404)
├── ValidationException (422)
└── ServerException (5xx)
```

### Error Flow

```dart
// API Layer
try {
  final response = await _dio.get(endpoint);
  return response.data;
} catch (e) {
  throw ErrorHandler.handle(e);  // Converts DioException to AppException
}

// Repository Layer
try {
  return await _api.getDevices();
} catch (e) {
  rethrow;  // Propagates to UI
}

// UI Layer
devicesAsync.when(
  error: (error, _) => AppErrorWidget(message: error.toString()),
)
```

## Dependency Injection with Riverpod

### Provider Creation

```dart
// API providers
final devicesApiProvider = Provider((_) => DevicesApi());

// Repository providers
final devicesRepositoryProvider = Provider((ref) {
  return DevicesRepository(ref.watch(devicesApiProvider));
});

// State providers
final devicesProvider = AsyncNotifierProvider<DevicesNotifier, List<DeviceModel>>(
  DevicesNotifier.new,
);

// Notifier accesses dependencies
class DevicesNotifier extends AsyncNotifier<List<DeviceModel>> {
  @override
  Future<List<DeviceModel>> build() async {
    return ref.watch(devicesRepositoryProvider).getDevices();
  }
}
```

## Model/DTO Pattern

### Network Models (DTOs)

```dart
@freezed
class DeviceResponse with _$DeviceResponse {
  const factory DeviceResponse({
    required String id,
    required String deviceId,
    required String deviceName,
  }) = _DeviceResponse;

  factory DeviceResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceResponseFromJson(json);
}
```

### Domain Models

```dart
@freezed
class DeviceModel with _$DeviceModel {
  const factory DeviceModel({
    required String id,
    required String deviceId,
    required String deviceName,
    required bool isActive,
  }) = _DeviceModel;

  factory DeviceModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceModelFromJson(json);
}
```

### Transformation

```dart
// API Response → Domain Model
DeviceModel _mapToModel(DeviceResponse response) {
  return DeviceModel(
    id: response.id,
    deviceId: response.deviceId,
    deviceName: response.deviceName,
    isActive: true,  // Apply business logic
  );
}
```

## Navigation Architecture

### GoRouter Navigation

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: _getInitialLocation(authState),
    redirect: (context, state) => _handleRedirects(authState, state),
    routes: [
      GoRoute(path: '/login', builder: ...),
      GoRoute(path: '/dashboard', builder: ...),
    ],
  );
});
```

### Route Types

```dart
// Simple route
GoRoute(path: '/profile', builder: (_, __) => const ProfilePage())

// Parameterized route
GoRoute(
  path: '/devices/:id',
  builder: (_, state) => DeviceDetailPage(id: state.pathParameters['id']!),
)

// Nested routes
GoRoute(
  path: '/dashboard',
  builder: (_, __) => const DashboardPage(),
  routes: [
    GoRoute(path: 'settings', builder: (_, __) => const SettingsPage()),
  ],
)
```

## Performance Optimization

### Avoiding Unnecessary Rebuilds

```dart
// ❌ Bad: Rebuilds entire widget
final dataAsync = ref.watch(dataProvider);

// ✅ Good: Only rebuilds when data changes
final dataAsync = ref.watch(dataProvider.select((async) => async.value?.length ?? 0));
```

### Caching Strategies

```dart
// Cache for 5 minutes
final cachedDataProvider = FutureProvider.autoDispose<Data>((ref) {
  return Future.delayed(const Duration(minutes: 5), () => fetchData());
});

// Keep alive after use
final persistentDataProvider = FutureProvider<Data>((ref) {
  return fetchData();
});
```

### Pagination

```dart
final paginationProvider = StateNotifierProvider<PaginationNotifier, int>(
  (_) => PaginationNotifier(),
);

class PaginationNotifier extends StateNotifier<int> {
  PaginationNotifier() : super(1);

  void nextPage() => state++;
  void previousPage() => state--;
  void reset() => state = 1;
}

final paginatedDataProvider = FutureProvider<List<Item>>((ref) {
  final page = ref.watch(paginationProvider);
  return _api.getItems(page: page);
});
```

## Testing Strategy

### Unit Tests

```dart
test('DevicesRepository.getDevices returns list', () async {
  final repo = DevicesRepository(mockApi);
  final devices = await repo.getDevices();
  expect(devices, isA<List<DeviceModel>>());
});
```

### Widget Tests

```dart
testWidgets('DeviceCard displays device info', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: DeviceCard(device: mockDevice),
  ));
  expect(find.text('Device Name'), findsOneWidget);
});
```

### Provider Tests

```dart
test('devicesProvider fetches devices', () async {
  final container = ProviderContainer();
  final devices = await container.read(devicesProvider.future);
  expect(devices, isNotEmpty);
});
```

## Best Practices

### 1. **Separation of Concerns**
- UI only handles rendering and user interaction
- State management handles logic coordination
- Repositories handle business rules
- APIs handle network communication

### 2. **Error Handling**
- Always catch exceptions at API level
- Transform to domain exceptions
- Display user-friendly messages in UI
- Log errors for debugging

### 3. **Type Safety**
- Use Freezed for immutable models
- Use strong typing throughout
- Avoid `dynamic` type

### 4. **State Management**
- Use AsyncNotifier for async operations
- Use StateNotifier for sync state
- Use FutureProvider for simple async reads
- Always handle loading, error, and data states

### 5. **Code Organization**
- One feature per directory
- Clear layer separation
- Reusable widgets in shared/
- Constants in core/config/

### 6. **Performance**
- Use .select() to watch specific properties
- Cache data appropriately
- Implement pagination for large lists
- Lazy load images and content

### 7. **Security**
- Store tokens in secure storage
- Validate user input
- Use HTTPS only
- Sanitize API responses

---

**Remember**: Good architecture is flexible, testable, and maintainable!
