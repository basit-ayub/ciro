# CIRO Mobile - Flutter App

This directory contains the Flutter codebase for the CIRO mobile application.
It includes the Live Reasoning Stadium (Wow #2), the Vision-first reporting UI (Wow #1), and the Counterfactual Twin Timeline UI (Wow #3).

## 🚀 How to build from this codebase

Since this code was generated via the Antigravity IDE without the local Flutter SDK installed, you need to "hydrate" the Flutter project wrappers.

### 1. Initialize the Project
From inside this `mobile` directory, run:
```bash
flutter create .
```
*(This will generate the `android/`, `ios/`, `web/`, and `windows/` platform folders while keeping our custom `lib/` and `pubspec.yaml` intact).*

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup Firebase
You need the Firebase CLI and FlutterFire CLI installed.
```bash
flutterfire configure
```
Select the Firebase project defined in the backend `.env` file. This will generate `lib/firebase_options.dart`.

### 4. Run the App
```bash
flutter run
```

---

## 📁 Key UI Files Created

- `pubspec.yaml`: Contains all packages (`flutter_riverpod`, `google_maps_flutter`, `firebase_core`, `lottie`, etc.).
- `lib/main.dart`: App entry point, Dark Theme definition, Riverpod scope.
- `lib/screens/map_screen.dart`: The primary Live Map with Google Maps overlay.
- `lib/widgets/live_reasoning_stadium.dart`: The 3 stacked agent cards for SSE streaming updates (Wow #2).
