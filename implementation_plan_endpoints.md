# Implementation Plan — Islamabad Route Endpoint Coordinate Alignment

This implementation plan outlines the steps required to correct the routing endpoints for the Islamabad emergency route (from PIMS Hospital to G-10 Markaz).

## User Review Required

No breaking changes are anticipated. This is a targeted calibration of coordinates to ensure the live OSRM routing snaps perfectly to major highways and landmarks.

## Open Questions

None. The exact coordinates have been verified against geographic standards:
- **PIMS Hospital Main Entrance (Ibn-e-Sina Road)**: `(33.7047, 73.0564)` (moving slightly north of the compound center `33.7037` to snap OSRM strictly to Ibn-e-Sina Road, avoiding G-8 Street 01 snap-to-road issues).
- **G-10 Markaz Crisis Hub**: `(33.6912, 73.0118)` (correcting the previous `(33.6938, 72.9910)` coordinate which terminated too far west at the E-11/F-10 crossroads boundary).

---

## Proposed Changes

### Mobile Client Component

#### [MODIFY] [confirmed_disasters_provider.dart](file:///d:/Side%20Projects/CIRO/mobile/lib/widgets/confirmed_disasters_provider.dart)
- Update PIMS Hospital coordinate from `LatLng(33.7037, 73.0564)` to `LatLng(33.7047, 73.0564)` to align perfectly with the main entrance on Ibn-e-Sina Road.
- Update Alternative Route Alpha and Beta coordinates list starts from `LatLng(33.7047, 73.0564)` to prevent fallback mismatches.

#### [MODIFY] [live_reasoning_stadium.dart](file:///d:/Side%20Projects/CIRO/mobile/lib/widgets/live_reasoning_stadium.dart)
- Locate the periodic simulator mock disaster publication event (around line 44).
- Update the published disaster coordinates from `lat: 33.6938, lng: 72.9910` to `lat: 33.6912, lng: 73.0118` to ensure the live simulation updates the feed with accurate G-10 Markaz endpoints instead of E-11/F-10.

---

### Backend & Mock Datasets Component

#### [MODIFY] [signal.py](file:///d:/Side%20Projects/CIRO/backend/models/signal.py)
- Calibrate the model configuration example coordinates to match the correct G-10 Markaz `(33.6912, 73.0118)`.

#### [MODIFY] [scenarios.json](file:///d:/Side%20Projects/CIRO/mock-data/scenarios.json)
- Correct the coordinate values for the G-10 Urban Flooding scenario from `33.6938, 72.9910` to `33.6912, 73.0118`.

#### [MODIFY] [social_feed.json](file:///d:/Side%20Projects/CIRO/mock-data/social_feed.json)
- Update mock social feed coordinates that represent G-10 Markaz signals from `33.6938` / `72.9910` to the verified `33.6912` / `73.0118`.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` in `mobile/` to verify zero static compiler errors.

### Manual Verification
- Run the mobile app on the physical Vivo V40 device.
- Trigger the live reasoning simulator and watch the disaster feed publish.
- Verify on the map:
  - The green and cyan route lines start **exactly** at PIMS Hospital main entrance on Ibn-e-Sina Road (not Street 01).
  - The destination marker sits **exactly** in Sector G-10 Markaz (not the crossroads of E-11/F-10).
