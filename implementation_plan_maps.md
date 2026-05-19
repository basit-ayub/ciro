# Goal: Fix Map Rendering and Implement Citizen Reporting

The Google Maps widget is currently crashing on Android because the newly generated Android scaffolding does not contain the required API Key metadata. Furthermore, we need to implement a dedicated interface for users to report crises from the field.

## Proposed Changes

### 1. Fix Google Maps Integration
- **`[MODIFY]` `mobile/android/app/src/main/AndroidManifest.xml`**:
  - Inject the `GOOGLE_MAPS_API_KEY` (from the environment configuration) as a `<meta-data>` tag under the `<application>` block so the Android SDK can successfully render the map tiles.

### 2. Citizen Reporting Interface
- **`[NEW]` `mobile/lib/screens/report_crisis_screen.dart`**:
  - Create a new Stateful widget for submitting crisis reports.
  - The UI will include:
    - A dropdown to select the Crisis Type (e.g., Flood, Fire, Riot).
    - A text field for providing contextual details.
    - A mock "Attach Image/Video" button simulating the Vision Agent input.
    - A "Submit Report" floating action button.
  - Submitting the form will trigger a mock success dialog and return to the Dashboard.

### 3. Navigation Update
- **`[MODIFY]` `mobile/lib/screens/main_navigation.dart`**:
  - Add a 4th tab to the `BottomNavigationBar` labeled **Report**.
  - Map the new `ReportCrisisScreen` to this tab.

## User Review Required

> [!TIP]
> This plan will fully activate the Google Maps plugin on the emulator and provide a complete citizen-facing reporting workflow to complement the agent dashboard. Do you approve?
