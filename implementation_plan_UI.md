# Goal: UI Overhaul & Android Emulator Setup

This plan details how we will transform CIRO from a single-screen Linux desktop prototype into a multi-screen, cohesive mobile application running inside a fully configured Android Virtual Device (Pixel emulator).

## Proposed Changes

### Phase 1: Android Environment Setup
Currently, `flutter doctor` reports that the Android SDK is missing. We will install the necessary components via command line.

- **Download SDK Tools**: Fetch the Android command-line tools via `wget`.
- **Install Components**: Use `sdkmanager` to install:
  - `platform-tools`
  - `platforms;android-33`
  - `build-tools;33.0.2`
  - `system-images;android-33;google_apis;x86_64` (for the emulator)
  - `emulator`
- **Configure Flutter**: Run `flutter config --android-sdk` to point to the newly downloaded SDK, and accept licenses via `flutter doctor --android-licenses`.
- **Create Emulator**: Use `avdmanager` to create a Pixel device named `ciro_pixel` using the downloaded system image.
- **Boot Emulator**: Launch the emulator in the background so it's ready for Flutter deployment.

### Phase 2: Flutter UI Architecture Overhaul
We will implement a complete, polished application flow.

#### [NEW] `mobile/lib/screens/splash_screen.dart`
- A startup page featuring the CIRO branding, a loading animation (using Lottie), and a mock "System Initialization" progress bar before routing to the main app.

#### [NEW] `mobile/lib/screens/main_navigation.dart`
- A persistent `BottomNavigationBar` to tie the app together, featuring:
  1. **Dashboard/HQ**: The `LiveReasoningStadium` (system status).
  2. **Live Map**: The `MapScreen` (the 5-zone Hell Mode map).
  3. **Simulator**: The `TwinTimelineWidget` (impact simulation).
  4. **Report (Vision)**: The citizen reporting / vision interface.

#### [MODIFY] `mobile/lib/main.dart`
- Update the root `MaterialApp` to use a dark, premium theme (aligned with the "rich aesthetics" guideline).
- Set `SplashScreen` as the initial route, which transitions to `MainNavigation`.

#### [MODIFY] `mobile/lib/widgets/live_reasoning_stadium.dart` & `twin_timeline.dart`
- Remove the `Scaffold` or outer padding that assumes they are standalone screens, adapting them to sit cleanly inside the `MainNavigation` tab views.

### Phase 3: Execution & Verification
- Once the UI is built and the emulator is booted, we will run `flutter run -d ciro_pixel` to deploy the app onto the Android emulator.

## User Review Required

> [!WARNING]
> Setting up the Android SDK and downloading the system images will consume around 2-3 GB of disk space and may take a few minutes to complete depending on network speeds. Do you approve proceeding with this environment setup?
