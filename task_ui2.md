# Map Fix & Reporting Workflow Tasks

- `[x]` **1. Android Google Maps Configuration**
  - `[x]` Open `mobile/android/app/src/main/AndroidManifest.xml`
  - `[x]` Inject `<meta-data android:name="com.google.android.geo.API_KEY" android:value="AIzaSyBU8rAMG0XEPygJCd89iMzyP8vYEeH7Ygs" />` into the application block.

- `[x]` **2. Citizen Reporting UI**
  - `[x]` Create `mobile/lib/screens/report_crisis_screen.dart`
  - `[x]` Implement dropdown for incident type
  - `[x]` Implement text area for details
  - `[x]` Implement image attachment mock button
  - `[x]` Implement submit action and success dialog

- `[x]` **3. Navigation Integration**
  - `[x]` Open `mobile/lib/screens/main_navigation.dart`
  - `[x]` Add a 4th `BottomNavigationBarItem`
  - `[x]` Add `ReportCrisisScreen` to the `_pages` array
