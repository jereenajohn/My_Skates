import 'dart:async';
import 'package:geolocator/geolocator.dart';

class RideService {
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return false;

    return perm == LocationPermission.whileInUse || perm == LocationPermission.always;
  }

  Future<void> start({
    required void Function(Position) onData,
    required void Function(Object) onError,
  }) async {
    _sub?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // small like Strava
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      onData,
      onError: onError,
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}