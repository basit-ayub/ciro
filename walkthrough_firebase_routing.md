# Walkthrough: Dynamic OSRM Road-Snapped Routing & Firestore Synchronizer

I have successfully resolved the road-routing polyline issues and completed the groundwork for dynamic, high-fidelity emergency responder navigation.

---

## 1. Dynamic OSRM Road Routing Overhaul (Road-Snapped Navigation)

### The Issue
Previously, polyline navigation paths were generated using sparse coordinate sets, resulting in Google Maps drawing straight diagonal vectors that cut through blocks, houses, and public buildings. 

### The Solution
Instead of relying on hardcoded straight lines, CIRO now **queries a real-time Open Source Routing Machine (OSRM) driving server** dynamically from the Flutter app.
1. **HTTP Client Integration**: Integrated the high-performance `Dio` network client.
2. **Dynamic Snapping**: When a disaster is added (either on boot, through mock streams, or from live database sync), CIRO queries `https://router.project-osrm.org` using the exact coordinate pairs of the Emergency Department (origin) and the disaster hub (destination).
3. **Detour Guiding Waypoints**: To maintain the distinction between **Route Alpha (Primary)** and **Route Beta (Secondary)** detours, we feed intermediate mock coordinates as routing waypoints. OSRM snaps these coordinates to the physical street layout, calculating two distinct, street-perfect routes.
4. **Blocked Segment Snapping**: The blocked hazard polyline is also dynamically routed and snapped along physical streets.
5. **State Preservation**: The provider checks if the disaster in the state already has high-density points. If so, it preserves the road points during agent reasoning state updates (e.g., *Sentinel Triaged* -> *Analyst Assessed* -> *Commander Dispatched*) rather than overwriting them with sparse arrays.

---

## 2. Clifton Karachi Grid Alignment

The Karachi heatwave simulation coordinate seeds in `LiveReasoningStadium` have been shifted from `(24.8607, 67.0011)` (Saddar) to `(24.8238, 67.0310)` (Clifton Block 5). This brings the incident marker directly within the South City Hospital Clifton routing graph bounds, creating perfect road-snapped polylines across Clifton's coastal roads and highways.

---

## 3. Firebase Connection Guide (Live Database Sync)

CIRO is fully equipped with live Firestore listening logic. The app will automatically sync in real-time when connected to your Firebase project.

### Step-by-Step Pairing Instructions for Hackathon Judges

To transition from offline mock mode to your live Firestore database:

1. **Install FlutterFire CLI**:
   Ensure you are logged into Firebase in your terminal, then install FlutterFire:
   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

2. **Configure Firebase**:
   Run the configurator in the `mobile` folder to bind your Firebase project:
   ```bash
   cd "d:\Side Projects\CIRO\mobile"
   flutterfire configure
   ```
   This will automatically generate the native `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files.

3. **Deploy the Firestore Collections**:
   Ensure your Firestore instance has a `situations` collection. Documents added to `situations` should follow the Pydantic schema:
   ```json
   {
     "incident_type": "Urban Flooding",
     "severity": 4,
     "confidence": 0.94,
     "status": "assessed",
     "geo": {
       "lat": 33.6938,
       "lon": 72.9910
     },
     "reasoning_trace": "Sentinel Triage completed: Srinagar Highway exit is flooded."
   }
   ```
   When a new document is written, CIRO's `listenToFirestore()` stream will instantly catch the update, plot the glowing cyan Emergency Department marker, trigger OSRM routing, and highlight the street-perfect paths live on the screen!

---

## 4. Verification & Clean Compile

We ran a full static code analysis and confirmed **zero compile-level errors**. The application has been compiled successfully and launched on your physical Vivo V40 Android handset (`10FEA807RY0003C`).
