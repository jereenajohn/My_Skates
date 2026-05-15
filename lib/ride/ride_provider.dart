import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'ride_math.dart';
import 'ride_models.dart';
import 'ride_service.dart';

class RideProvider extends ChangeNotifier {
  final RideService _service = RideService();

  RideUIState uiState = RideUIState.initialMap;
  SportType selectedSport = SportType.ride;

  bool isRunning = false;
  bool isManualPaused = false;
  bool isAutoPaused = false;

  Duration elapsed = Duration.zero;
  Duration moving = Duration.zero;
  Timer? _ticker;

  double distanceKm = 0.0;
  double currentSpeedKmh = 0.0;
  double avgSpeedKmh = 0.0;

  Position? _lastPos;
  Position? currentPosition;

  int _stoppedSeconds = 0;

  DateTime? startedAt;
  DateTime? endedAt;

  final List<Position> route = [];

  double get autoPauseSpeedThresholdKmh => selectedSport.isCycle ? 2.2 : 1.0;
  int get autoPauseAfterSeconds => 5;

  double get maxSpeedKmh {
    double max = 0;
    for (int i = 1; i < route.length; i++) {
      final prev = route[i - 1];
      final next = route[i];

      final dt =
          (next.timestamp.difference(prev.timestamp ?? DateTime.now()).inSeconds ??
              1);
      if (dt <= 0) continue;

      final meters = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        next.latitude,
        next.longitude,
      );

      final speed = RideMath.msToKmh(meters / dt);
      if (speed > max) max = speed;
    }
    return max;
  }

  void openChooseSport() {
    uiState = RideUIState.chooseSport;
    notifyListeners();
  }

  void selectSport(SportType sport) {
    selectedSport = sport;
    uiState = RideUIState.readyCompact;
    notifyListeners();
  }

  void toggleExpandReady() {
    if (uiState == RideUIState.readyCompact) {
      uiState = RideUIState.readyExpanded;
    } else if (uiState == RideUIState.readyExpanded) {
      uiState = RideUIState.readyCompact;
    }
    notifyListeners();
  }

  Future<void> startPressed() async {
    final ok = await _service.ensurePermission();
    if (!ok) return;

    isRunning = true;
    isManualPaused = false;
    isAutoPaused = false;

    elapsed = Duration.zero;
    moving = Duration.zero;
    distanceKm = 0;
    currentSpeedKmh = 0;
    avgSpeedKmh = 0;

    route.clear();
    _lastPos = null;
    currentPosition = null;
    _stoppedSeconds = 0;

    startedAt = DateTime.now();
    endedAt = null;

    uiState = RideUIState.tracking;
    _startTicker();

    await _service.start(
      onData: _onPosition,
      onError: (e) => debugPrint("GPS error: $e"),
    );

    notifyListeners();
  }

  void pausePressed() {
    isManualPaused = true;
    isAutoPaused = false;
    currentSpeedKmh = 0;
    uiState = RideUIState.paused;
    notifyListeners();
  }

  void stopPressed() {
    isManualPaused = true;
    isAutoPaused = false;
    currentSpeedKmh = 0;
    uiState = RideUIState.stopped;
    notifyListeners();
  }

  void finishPressed() {
    isRunning = false;
    currentSpeedKmh = 0;
    endedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = null;
    uiState = RideUIState.saveActivity;
    notifyListeners();
  }

  void resumePressed() {
    isManualPaused = false;
    isAutoPaused = false;
    _stoppedSeconds = 0;
    currentSpeedKmh = 0;
    uiState = RideUIState.tracking;
    notifyListeners();
  }

  Future<void> stopAll() async {
    await _service.stop();
    _ticker?.cancel();
    _ticker = null;
    isRunning = false;
    isManualPaused = false;
    isAutoPaused = false;
    currentSpeedKmh = 0;
    notifyListeners();
  }

  Map<String, dynamic> buildActivityPayload({
    required String title,
    required String description,
    String? activityTag,
    String? feeling,
    String? privateNote,
  }) {
    final Position? first = route.isNotEmpty ? route.first : null;
    final Position? last = route.isNotEmpty ? route.last : null;

    return {
      "title": title,
      "description": description,
      "sport": selectedSport.label,
      "sport_key": selectedSport.name,
      "activity_log": activityTag ?? "",
      "feeling": feeling ?? "",
      "private_note": privateNote ?? "",
      "started_at": startedAt?.toIso8601String(),
      "ended_at": endedAt?.toIso8601String(),
      "elapsed_seconds": elapsed.inSeconds,
      "moving_seconds": moving.inSeconds,
      "distance_km": double.parse(distanceKm.toStringAsFixed(2)),
      "average_speed_kmh": double.parse(avgSpeedKmh.toStringAsFixed(2)),
      "current_speed_kmh": double.parse(currentSpeedKmh.toStringAsFixed(2)),
      "max_speed_kmh": double.parse(maxSpeedKmh.toStringAsFixed(2)),
      "is_auto_paused": isAutoPaused,
      "start_latitude": first?.latitude.toString(),
      "start_longitude": first?.longitude.toString(),
      "end_latitude": last?.latitude.toString(),
      "end_longitude": last?.longitude.toString(),
      "route_points": route
          .map(
            (p) => {
              "latitude": p.latitude,
              "longitude": p.longitude,
              "accuracy": p.accuracy,
              "altitude": p.altitude,
              "speed": p.speed,
              "heading": p.heading,
              "timestamp": p.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRunning) return;

      elapsed += const Duration(seconds: 1);

      final pausedNow = isManualPaused || isAutoPaused;
      if (!pausedNow) {
        moving += const Duration(seconds: 1);
      }

      final movingHrs = moving.inSeconds / 3600.0;
      avgSpeedKmh = movingHrs > 0 ? distanceKm / movingHrs : 0;

      notifyListeners();
    });
  }

  void _onPosition(Position p) {
    if (!isRunning) return;

    currentPosition = p;

    // Strong accuracy filter
    if (p.accuracy <= 0 || p.accuracy > 12) {
      notifyListeners();
      return;
    }

    if (_lastPos == null) {
      _lastPos = p;
      route.add(p);
      notifyListeners();
      return;
    }

    final meters = Geolocator.distanceBetween(
      _lastPos!.latitude,
      _lastPos!.longitude,
      p.latitude,
      p.longitude,
    );

    final dt =
        (p.timestamp.difference(_lastPos!.timestamp ?? DateTime.now()).inSeconds ??
            1);

    if (dt <= 0) return;

    final rawSpeedKmh = RideMath.msToKmh(meters / dt);

    // Reject impossible spikes
    if (selectedSport.isCycle && rawSpeedKmh > 65) {
      _lastPos = p;
      notifyListeners();
      return;
    }
    if (!selectedSport.isCycle && rawSpeedKmh > 25) {
      _lastPos = p;
      notifyListeners();
      return;
    }

    // Stationary / GPS drift
    final bool likelyDrift =
        meters < 4 || (meters < 7 && rawSpeedKmh < autoPauseSpeedThresholdKmh);

    if (likelyDrift) {
      currentSpeedKmh = 0;
      _lastPos = p;

      if (!isManualPaused) {
        _stoppedSeconds++;
        if (_stoppedSeconds >= autoPauseAfterSeconds) {
          isAutoPaused = true;
          uiState = RideUIState.autoPaused;
        }
      }

      notifyListeners();
      return;
    }

    currentSpeedKmh = RideMath.smooth(
      currentSpeedKmh,
      rawSpeedKmh,
      alpha: 0.35,
    );

    final bool realMovement =
        meters >= 5 &&
        rawSpeedKmh >= autoPauseSpeedThresholdKmh &&
        p.accuracy <= 12;

    if (realMovement) {
      _stoppedSeconds = 0;

      if (isAutoPaused) {
        isAutoPaused = false;
        uiState = RideUIState.tracking;
      }

      final pausedNow = isManualPaused || isAutoPaused;

      if (!pausedNow) {
        distanceKm += RideMath.metersToKm(meters);
        route.add(p);
      }
    } else {
      if (!isManualPaused) {
        _stoppedSeconds++;
        if (_stoppedSeconds >= autoPauseAfterSeconds) {
          isAutoPaused = true;
          uiState = RideUIState.autoPaused;
        }
      }
      currentSpeedKmh = 0;
    }

    _lastPos = p;
    notifyListeners();
  }
}