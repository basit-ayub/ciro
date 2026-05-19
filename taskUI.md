# UI Overhaul & Android Setup Tasks

- `[ ]` **1. Android SDK & Emulator Setup**
  - `[ ]` Download and extract Android command-line tools
  - `[ ]` Install platforms, build-tools, system-images via `sdkmanager`
  - `[ ]` Configure Flutter Android SDK path & accept licenses
  - `[ ]` Create `ciro_pixel` AVD via `avdmanager`
  - `[ ]` Boot the emulator in the background

- `[ ]` **2. UI Architecture Overhaul**
  - `[ ]` Create `mobile/lib/screens/splash_screen.dart`
  - `[ ]` Create `mobile/lib/screens/main_navigation.dart`
  - `[ ]` Modify `mobile/lib/main.dart` to use premium theme and new routing
  - `[ ]` Adapt existing widgets (Stadium, Map, Timeline) to fit inside tab views

- `[ ]` **3. Execution**
  - `[ ]` Run app on emulator using `flutter run -d ciro_pixel`
