# 📱 SAV Mobile Application - Technical & Architectural Manual

Welcome to the official developer and architecture documentation for the **SAV (Smart Automotive Vision)** Mobile Application. This application serves as the in-cabin safety hub and Head-Up Display (HUD) for commercial truck drivers, executing real-time navigation, in-app communications, and safety alerts.

---

## 📂 1. Directory Structure & Architecture Mappings

The mobile application is built strictly under the principles of **Clean Architecture** combined with the **BLoC (Business Logic Component)** pattern, ensuring modularity, absolute testability, and strict separation of concerns.

```
lib/
├── core/
│   ├── api/             # Dio HTTP client, interceptors, and requests
│   ├── constants/       # Global AppColors, AppAssets, and AppConstants
│   ├── di/              # GetIt service locator & dependency injection configuration
│   ├── errors/          # Failures and error extraction logic
│   ├── network/         # Internet connectivity service wrappers
│   ├── services/        # Hardware/Device services (Location, LocalServer, AlertPlayer, Wakelock)
│   ├── util/            # Custom routing (AppRouter) and layout helper extensions
│   └── widgets/         # Globally reused UI components (buttons, custom cards, dialogs)
│
└── features/
    ├── alerts/          # Driver safety alerts entities and repositories
    ├── auth/            # Authentication cubits, views, and data models
    ├── common/          # Global layout structure, bottom navbar routing, and chat widgets
    ├── emergency/       # Real-time GPS coordinate SOS emergency reporting
    ├── history/         # Driver trip and statistics history views
    ├── home/            # Home dashboard statistics card summaries
    ├── notifications/   # System push notifications bindings (FCM registration)
    ├── settings/        # Sound profile configs, vibration settings, and preferences
    ├── splash/          # App initialization sequence routing
    └── trip/            # The Core Feature: Maps, Trip State, Local Server, and Overlay HUD
```

Each module under `features/` is split into:
1. **Data Layer (`data/`):** Contains models (DTOs), remote/local datasources, and repository implementations.
2. **Domain Layer (`domain/`):** Contains business entities, usecases, and repository interfaces (completely framework-independent).
3. **Presentation Layer (`presentation/`):** Contains BLoC/Cubit state controllers, UI views (Screens), and local widgets.

---

## ⚙️ 2. State Management & Lifecycle Flow

We use **Flutter BLoC (Cubit)** for reactive state coordination. The app updates dynamically without full-screen redraws by utilizing scoped `BlocBuilder` and `BlocConsumer` widgets.

```
                  [Telemetry Trigger / FCM Message]
                                 │
                                 v
                       TripCubit.listen(...)
                                 │
                                 v
    [Safe State] ─────────────────────────────────> [Danger State]
  Updates active stats                            Emits TripDangerAlert
  (Awake %, Alerts Today)                         Fades-in Safety Red Overlay
         │                                               │
         v                                               v
Renders Safe Map Screen                          Triggers Alarm & Vibration
```

### Core Cubits in Action:
* **`TripCubit`:** The primary system controller. It manages map states, location tracking intervals, starts/stops the local HTTP fallback server, listens to incoming telemetry, and triggers safety warning states.
* **`HomeCubit`:** Controls the home tab dashboard statistics. It fetches aggregate daily driving durations, alert counts, and averages (Awake % / Distracted %).
* **`DriverDataCubit`:** Holds authenticated driver profile states, settings, and vehicle mapping bindings.

---

## 📡 3. In-Cabin Local Telemetry Server (Offline Fallback)

To guarantee 100% driver protection on remote desert highways where cellular signals drop, the SAV mobile application acts as a standalone edge server.

```
+------------------+         Local In-Cabin Wi-Fi          +--------------------+
| ESP32-CAM Node   | ------------------------------------> | Flutter App Server |
| (QVGA JPEG Stream) |     [POST /esp over Port 8080]      | (LocalTelemetry)   |
+------------------+                                       +--------------------+
                                                                     |
                                                                     v
                                                            TripCubit Ingestion
                                                                     |
                                                                     v
                                                            Local UI Danger Alert
```

* **Server Bind:** On trip startup, `TripCubit` triggers `LocalTelemetryServer.start()`, which spins up a dart `HttpServer` bound to:
  `HttpServer.bind(InternetAddress.anyIPv4, 8080)`
* **Endpoint Processing:** The server listens on `POST /esp` or `POST /api/esp/ingest`. It decodes the incoming JSON binary payload in memory:
  - Extract values: `face_detected`, `eye_alert`, `yawn`, `head_down`, `score` (confidence).
  - Add parameters immediately to a broadcast `StreamController<Map<String, dynamic>>`.
* **State Mapping:** `TripCubit` listens to this local stream. If the payload indicates an active danger status, it bypasses the internet, launches local alarms, and pushes `TripDangerAlert` to update the screen.
* **Offline Caching:** The alert is cached locally using **Hive** storage. Once the internet returns, the app automatically syncs offline records back to the Django API.

---

## 🔒 4. Memory Leakage & Resource Management Policies

Safety apps must run stably for hours without crashing or lagging. We enforce defensive coding practices to prevent memory leakages across the application:

1. **Stream Subscriptions Cancellation:** Streams like Local Server Telemetry and FCM messaging can leak RAM. We override BLoC's `close()` method to cancel subscriptions:
   ```dart
   @override
   Future<void> close() {
     _fcmAlertSubscription?.cancel();
     _localTelemetrySubscription?.cancel();
     _stopAllSubsystems();
     return super.close();
   }
   ```
2. **Native Platform Disposal:** On screen dispose, we explicitly trigger garbage collection releases:
   - `_mapController?.dispose()` (Releases Google Maps native engine).
   - `_alertAnimController.dispose()` (Cleans up vsync animation ticks).
   - `_player.dispose()` (Frees OS audio buffers).
3. **Screen Wakelock Lifecycle:** We use `WakelockPlus` to force the screen to stay awake while driving. On session stop or cancel, we release this lock to prevent battery depletion:
   ```dart
   WakelockPlus.enable();  // On Trip Start/Resume
   WakelockPlus.disable(); // On Trip Stop/Cancel
   ```

---

## 🚨 5. Audio, Visual, & Haptic Alert Pipeline

The app coordinates a multi-sensory safety feedback loop to alert the driver depending on the severity of the drowsiness or distraction:

### A. Visual Warning Overlay
If the state changes to `TripDangerAlert`, the screen immediately swaps navigation maps for a high-priority warning layout:
* **Background:** Solid warning red `Color(0xFFEF401D)`.
* **Visuals:** Flashing warning/siren vector graphics.
* **Dismissal:** Requires the driver to press a large **"Awake"** button, which runs `acknowledgeAlert()` to restore maps navigation.

### B. Audio Alarm Routing
We use the `audioplayers` package with system-level alarm routing to override the phone's silent or do-not-disturb modes:
* **Android:** Configured to `AndroidUsageType.alarm` and `AndroidContentType.sonification` with transient audio focus (ducking navigation voices).
* **iOS:** Mapped to `AVAudioSessionCategory.playback` routed directly to default speaker outputs.
* **Assets:** Runs custom audio buzzer alarms like `trucksound.wav` or `warning.wav` depending on the warning type (drowsiness vs yawning).

### C. Haptic Vibration Pulses
We integrate the `vibration` plugin to alert drivers physically:
* **Drowsiness/Sleep alerts:** A heavy, 1000ms vibration warning pulse.
* **Yawning/Distraction alerts:** A shorter, 500ms haptic feedback.

---

## 🛠️ 6. Tech Stack & Critical Packages

* **Core Platform:** Flutter SDK
* **State Management:** `flutter_bloc` & `bloc` (v8.1+)
* **HTTP Network Client:** `dio` with JWT Token interceptors & automatic refresh flows
* **Dependency Injection:** `get_it` & `injectable` (Code-generated lazy singletons)
* **Local Database Caching:** `hive` & `hive_flutter` (High-speed key-value offline storage)
* **Map & Navigation:** `google_maps_flutter` & `geolocator`
* **Audio Engine:** `audioplayers` (System alarms routing)
* **Haptics:** `vibration`
* **Display Control:** `wakelock_plus`
* **Responsive Layouts:** `flutter_screenutil`

---

## 🚀 7. Developer Setup & Build Instructions

### Prerequisites
* Flutter SDK (Version 3.19.x or higher)
* Android Studio (with Android SDK 34+) / Xcode (for iOS builds)
* Google Maps API Key (configured in `AndroidManifest.xml` / `AppDelegate.swift`)

### Installation Steps
1. Clone the repository and navigate to the application folder:
   ```bash
   cd "Graduation Project/Application"
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run code generation for Dependency Injection (injectable config):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run the app in development mode:
   ```bash
   flutter run
   ```
5. Compile production builds:
   - **Android APK:**
     ```bash
     flutter build apk --release
     ```
   - **iOS IPA:**
     ```bash
     flutter build ipa --release
     ```
