import 'package:geolocator/geolocator.dart';

class LocationServiceDisabledException implements Exception {}

class LocationPermissionDeniedException implements Exception {}

class LocationPermissionDeniedForeverException implements Exception {}

class LocationService {
  // Checks the current permission and, if not yet decided, triggers the
  // native OS permission popup. Returns the resulting permission status.
  Future<LocationPermission> ensurePermissionRequested() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationServiceDisabledException();
    }

    final permission = await ensurePermissionRequested();

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException();
    }
    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
