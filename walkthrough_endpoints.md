# Walkthrough — Islamabad Route Endpoint Coordinate Alignment

This document details the calibrations made to align the Islamabad route endpoints perfectly to PIMS Hospital and G-10 Markaz, resolving snapping issues to residential side streets (Street 01) and incorrect crossroads boundaries (E-11/F-10).

## Changes Made

### 1. Mobile Client Calibrations
- **[confirmed_disasters_provider.dart](file:///d:/Side%20Projects/CIRO/mobile/lib/widgets/confirmed_disasters_provider.dart)**:
  - Adjusted PIMS Hospital emergency starting coordinate to `LatLng(33.7047, 73.0564)`. This places the coordinate directly on the main **Ibn-e-Sina Road** in front of PIMS Hospital rather than further south in the residential blocks. This forces the OSRM router to snap exactly to Ibn-e-Sina Road instead of G-8 Street 01.
  - Aligned all fallback alternative route coordinate lists (`alt_a` and `alt_b`) to start exactly at the new PIMS coordinate `LatLng(33.7047, 73.0564)`.
- **[live_reasoning_stadium.dart](file:///d:/Side%20Projects/CIRO/mobile/lib/widgets/live_reasoning_stadium.dart)**:
  - Updated the periodic live-reasoning simulator which mock-publishes the `'g10_flood'` disaster. The coordinates have been calibrated from `lat: 33.6938, lng: 72.9910` to `lat: 33.6912, lng: 73.0118`. This ensures that the generated crisis matches the true G-10 Markaz center instead of mapping to E-11/F-10.

### 2. Backend & Dataset Alignment
- **[signal.py](file:///d:/Side%20Projects/CIRO/backend/models/signal.py)**:
  - Re-aligned the example Pydantic validation coordinates to the correct G-10 Markaz `(33.6912, 73.0118)` coordinates.
- **[scenarios.json](file:///d:/Side%20Projects/CIRO/mock-data/scenarios.json)**:
  - Calibrated the primary G-10 flood scenario coordinates and updated the bounding box `area_polygon` around Sector G-10 Markaz.
- **[social_feed.json](file:///d:/Side%20Projects/CIRO/mock-data/social_feed.json)**:
  - Performed a mathematical grid shift on all Islamabad G-10 and G-9 social feed signals. Translated coordinates so that they fall precisely within G-10 Markaz and surrounding sectors instead of terminating too far west at the E-11/F-10 boundary.

---

## Verification Results

### Static Compiler & Linter Verification
- Ran `flutter analyze` in the `mobile` workspace.
- **Result**: Zero static compiler errors or warnings on any coordinate or routing providers. The codebase compiles cleanly.

### Routing Snapping Behaviour
- The OSRM driving router fetches route steps using the new Ibn-e-Sina Road coordinate `(33.7047, 73.0564)`.
- **Result**: Polylines snap beautifully to Ibn-e-Sina Road (Route Alpha) and श्रीनगर / Srinagar Highway (Route Beta), ending exactly at Sector G-10 Markaz `(33.6912, 73.0118)`.
