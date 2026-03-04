import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'ride_math.dart';
import 'ride_models.dart';
import 'ride_service.dart';

class RideProvider extends ChangeNotifier {
  final RideService _service = RideService();

  // UI
  RideUIState uiState = RideUIState.initialMap;
  SportType selectedSport = SportType.ride;

  // Tracking
  bool isRunning = false;
  bool isManualPaused = false; // user pressed Stop / Pause
  bool isAutoPaused = false;

  Duration elapsed = Duration.zero;  // wall clock since start
  Duration moving = Duration.zero;   // Strava-like moving time
  Timer? _ticker;

  double distanceKm = 0.0;
  double currentSpeedKmh = 0.0;
  double avgSpeedKmh = 0.0;

  Position? _lastPos;
  int _stoppedSeconds = 0;

  // simple route polyline
  final List<Position> route = [];

  // thresholds (tune as you wish)
  double get autoPauseSpeedThresholdKmh => selectedSport.isCycle ? 1.2 : 0.8;
  int get autoPauseAfterSeconds => 8;

  // ---------- UI actions (exact flow) ----------
  void openChooseSport() {
    uiState = RideUIState.chooseSport;
    notifyListeners();
  }

  void selectSport(SportType sport) {
    selectedSport = sport;
    uiState = RideUIState.readyCompact; // screenshot 1 panel after selection
    notifyListeners();
  }

  void toggleExpandReady() {
    if (uiState == RideUIState.readyCompact) {
      uiState = RideUIState.readyExpanded; // screenshot 3
    } else if (uiState == RideUIState.readyExpanded) {
      uiState = RideUIState.readyCompact;
    }
    notifyListeners();
  }

  Future<void> startPressed() async {
    final ok = await _service.ensurePermission();
    if (!ok) {
      // stay same but you can show snackbar in UI
      return;
    }

    // reset tracking
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
    _stoppedSeconds = 0;

    uiState = RideUIState.tracking; // screenshot 4
    _startTicker();

    await _service.start(
      onData: _onPosition,
      onError: (e) => debugPrint("GPS error: $e"),
    );

    notifyListeners();
  }

  void pausePressed() {
    // screenshot 4 "Pause" → we interpret as "manual pause"
    isManualPaused = true;
    uiState = RideUIState.stopped; // looks like screenshot 7 (stopped)
    notifyListeners();
  }

  void resumePressed() {
    isManualPaused = false;
    isAutoPaused = false;
    _stoppedSeconds = 0;
    uiState = RideUIState.tracking; // screenshot 4 with pause button
    notifyListeners();
  }

  void finishPressed() {
    uiState = RideUIState.saveActivity; // screenshot 8
    notifyListeners();
  }

  Future<void> stopAll() async {
    await _service.stop();
    _ticker?.cancel();
    _ticker = null;
    isRunning = false;
    isManualPaused = false;
    isAutoPaused = false;
    notifyListeners();
  }

  // ---------- ticker ----------
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRunning) return;

      elapsed += const Duration(seconds: 1);

      final pausedNow = isManualPaused || isAutoPaused;
      if (!pausedNow) moving += const Duration(seconds: 1);

      final movingHrs = moving.inSeconds / 3600.0;
      if (movingHrs > 0) avgSpeedKmh = distanceKm / movingHrs;

      notifyListeners();
    });
  }

  // ---------- GPS ----------
  void _onPosition(Position p) {
    if (!isRunning) return;

    // ignore poor accuracy
    if (p.accuracy > 25) return;

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

    final dt = (p.timestamp?.difference(_lastPos!.timestamp ?? DateTime.now()).inSeconds ?? 1);
    if (dt <= 0) return;

    // reject small drift
    if (meters < 2) return;

    final speedMs = meters / dt;
    final speedKmh = RideMath.msToKmh(speedMs);

    // reject crazy jumps
    if (selectedSport.isCycle && speedKmh > 80) return;
    if (!selectedSport.isCycle && speedKmh > 35) return;

    currentSpeedKmh = RideMath.smooth(currentSpeedKmh, speedKmh, alpha: 0.2);

    final pausedNow = isManualPaused || isAutoPaused;

    // auto pause detection
    if (!isManualPaused) {
      if (currentSpeedKmh < autoPauseSpeedThresholdKmh) {
        _stoppedSeconds++;
        if (_stoppedSeconds >= autoPauseAfterSeconds) {
          isAutoPaused = true;
          uiState = RideUIState.autoPaused; // screenshot 6
        }
      } else {
        _stoppedSeconds = 0;
        if (isAutoPaused) {
          isAutoPaused = false;
          uiState = RideUIState.tracking;
        }
      }
    }

    // add distance only if not paused
    if (!pausedNow && currentSpeedKmh > autoPauseSpeedThresholdKmh) {
      distanceKm += RideMath.metersToKm(meters);
    }

    route.add(p);
    _lastPos = p;

    notifyListeners();
  }
}