# Goal: Image Upload Feature and Emulator Performance Optimization

The emulator is throwing "System UI not responding" popups because the default Android Virtual Device (AVD) allocates a very small amount of RAM (1.5GB) which is insufficient for running heavy Google Maps and Flutter debugging simultaneously. 

Additionally, we need to upgrade the mock "Attach Image" button to launch the native Android photo gallery.

## Proposed Changes

### 1. Emulator Performance Tuning (Fixing the ANRs)
- **`[MODIFY]` `~/.android/avd/ciro_pixel.avd/config.ini`**:
  - We will surgically increase `hw.ramSize` from `1536M` to `3072M` (3GB).
  - We will increase `vm.heapSize` from `228M` to `512M`.
  - *Note: You will need to restart the emulator for these changes to take effect.*

### 2. Gallery Integration
- **`[NEW DEPENDENCY]` `image_picker`**:
  - Run `flutter pub add image_picker` in the mobile directory to add the official Flutter plugin for accessing the device's media library.
- **`[MODIFY]` `mobile/lib/screens/report_crisis_screen.dart`**:
  - Import the `image_picker` package.
  - Implement an asynchronous method `_pickImage()` that uses `ImagePicker().pickImage(source: ImageSource.gallery)`.
  - Update the UI state to display the name or a preview of the selected image instead of just toggling a mock boolean flag.

## User Review Required
> [!WARNING]
> Because we are integrating a native plugin (`image_picker`), a simple "Hot Reload" will not be enough. After I make these changes, you will need to completely stop the emulator, restart it (so it gets the 3GB RAM boost), and then run `flutter run` again. 
> 
> Do you approve this plan?
