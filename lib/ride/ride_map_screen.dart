import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'ride_provider.dart';
import 'ride_models.dart';
import 'ride_math.dart';
import 'ride_service.dart';
import 'save_activity_screen.dart';
import 'widgets.dart';

class RideMapScreen extends StatefulWidget {
  const RideMapScreen({super.key});

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  GoogleMapController? _map;
  final RideService _rideService = RideService();

  bool _didOpenSave = false;
  bool _initialCentered = false;
  int _lastAnimatedRouteCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final pos = await _rideService.getCurrentPosition();
    if (!mounted || pos == null) return;

    final ride = context.read<RideProvider>();
    ride.currentPosition = pos;
    ride.notifyListeners();

    if (_map != null) {
      await _animateTo(pos.latitude, pos.longitude, zoom: 17.2);
      _initialCentered = true;
    }
  }

  Future<void> _animateTo(
    double lat,
    double lng, {
    double zoom = 17,
    double tilt = 0,
    double bearing = 0,
  }) async {
    await _map?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: zoom,
          tilt: tilt,
          bearing: bearing,
        ),
      ),
    );
  }

  void _handleMapFollow(RideProvider ride) {
    final pos = ride.currentPosition;
    if (_map == null || pos == null) return;

    if (!_initialCentered) {
      _animateTo(pos.latitude, pos.longitude, zoom: 17.2);
      _initialCentered = true;
      return;
    }

    final shouldFollow =
        ride.uiState == RideUIState.tracking ||
        ride.uiState == RideUIState.autoPaused ||
        ride.uiState == RideUIState.stopped ||
        ride.uiState == RideUIState.paused;

   if (shouldFollow) {
  if (ride.route.length != _lastAnimatedRouteCount || ride.currentSpeedKmh > 0) {
    _lastAnimatedRouteCount = ride.route.length;
    _animateTo(
      pos.latitude,
      pos.longitude,
      zoom: 17.2,
      tilt: 45,
      bearing: pos.heading.isFinite ? pos.heading : 0,
    );
  }
}
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ride.uiState == RideUIState.saveActivity && !_didOpenSave) {
        _didOpenSave = true;
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => const SaveActivityScreen(),
              ),
            )
            .then((_) {
              _didOpenSave = false;
              ride.stopAll();
              ride.uiState = RideUIState.initialMap;
              ride.notifyListeners();
            });
      }

      _handleMapFollow(ride);
    });

    final List<LatLng> routePoints = ride.route
        .map((position) => LatLng(position.latitude, position.longitude))
        .toList();

    final polyline = Polyline(
      polylineId: const PolylineId("route"),
      width: 7,
      color: const Color(0xFF7A5CFF),
      points: routePoints,
    );

    final LatLng initialTarget = ride.currentPosition != null
        ? LatLng(
            ride.currentPosition!.latitude,
            ride.currentPosition!.longitude,
          )
        : const LatLng(9.9312, 76.2673);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 16.5,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            polylines: {polyline},
            onMapCreated: (controller) async {
              _map = controller;
              final pos = ride.currentPosition;
              if (pos != null) {
                await _animateTo(pos.latitude, pos.longitude, zoom: 17.2);
                _initialCentered = true;
              }
            },
          ),
          Positioned(
            top: 56,
            right: 16,
            child: _CircleIcon(
              icon: Icons.my_location,
              onTap: () async {
                final pos =
                    ride.currentPosition ??
                    await _rideService.getCurrentPosition();
                if (pos != null) {
                  await _animateTo(pos.latitude, pos.longitude, zoom: 17.2);
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _bottomPanel(context, ride),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel(BuildContext context, RideProvider ride) {
    if (ride.uiState == RideUIState.chooseSport) {
      return _chooseSportSheet(context, ride);
    }

    if (ride.uiState == RideUIState.readyExpanded) {
      return _expandedStatsPanel(context, ride);
    }

    if (ride.uiState == RideUIState.tracking) {
      return _trackingPanel(context, ride);
    }

    if (ride.uiState == RideUIState.autoPaused) {
      return _autoPausedPanel(context, ride);
    }

    if (ride.uiState == RideUIState.paused) {
      return _pausedPanel(context, ride);
    }

    if (ride.uiState == RideUIState.stopped) {
      return _stoppedPanel(context, ride);
    }

    return _initialOrReadyPanel(context, ride);
  }

  Widget _initialOrReadyPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: RideMath.formatDuration(ride.moving).substring(3),
            leftLabel: "Time",
            midValue: ride.avgSpeedKmh.toStringAsFixed(1),
            midLabel: "Avg. speed",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance",
            onExpand: ride.uiState == RideUIState.readyCompact
                ? ride.toggleExpandReady
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SmallModeButton(
                selected: true,
                icon: Icons.directions_bike,
                label: ride.selectedSport.isCycle
                    ? "Ride"
                    : ride.selectedSport.label,
                onTap: ride.openChooseSport,
              ),
              _BigStartButton(
                label: "Start",
                onTap: () async {
                  await ride.startPressed();
                },
              ),
              _SmallModeButton(
                selected: false,
                icon: Icons.alt_route,
                label: "Add Route",
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _chooseSportSheet(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Choose a Sport",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ride.uiState = RideUIState.readyCompact;
                    ride.notifyListeners();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Foot Sports",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _sportRow(ride, SportType.run, Icons.directions_run),
                  _sportRow(ride, SportType.trailRun, Icons.terrain),
                  _sportRow(ride, SportType.walk, Icons.directions_walk),
                  _sportRow(ride, SportType.hike, Icons.hiking),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Cycle Sports",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _sportRow(ride, SportType.ride, Icons.directions_bike),
                  _sportRow(ride, SportType.mtb, Icons.pedal_bike),
                  _sportRow(
                    ride,
                    SportType.gravel,
                    Icons.directions_bike_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sportRow(RideProvider ride, SportType sport, IconData icon) {
    final selected = ride.selectedSport == sport;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.teal : Colors.white),
      title: Text(
        sport.label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: selected ? Colors.teal : Colors.white,
        ),
      ),
      trailing: selected ? const Icon(Icons.check, color: Colors.teal) : null,
      onTap: () => ride.selectSport(sport),
    );
  }

  Widget _expandedStatsPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: ride.toggleExpandReady,
                  icon: const Icon(Icons.open_in_full, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              RideMath.formatDuration(ride.moving),
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 30),
            Text(
              ride.avgSpeedKmh.toStringAsFixed(1),
              style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Avg. speed (km/h)",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              ride.distanceKm.toStringAsFixed(2),
              style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Distance (km)",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SmallModeButton(
                  selected: true,
                  icon: Icons.directions_bike,
                  label: ride.selectedSport.isCycle
                      ? "Ride"
                      : ride.selectedSport.label,
                  onTap: ride.openChooseSport,
                ),
                _BigStartButton(
                  label: "Start",
                  onTap: () => ride.startPressed(),
                ),
                _SmallModeButton(
                  selected: false,
                  icon: Icons.alt_route,
                  label: "Add Route",
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _trackingPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: _mmss(ride.moving),
            leftLabel: "Time",
            midValue: ride.currentSpeedKmh.toStringAsFixed(1),
            midLabel: "Speed (km/h)",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance (km)",
          ),
          const SizedBox(height: 14),
          DualButtons(
            leftText: "Pause",
            leftIcon: Icons.pause,
            onLeft: ride.pausePressed,
            rightText: "Stop",
            rightIcon: Icons.stop,
            onRight: ride.stopPressed,
          ),
        ],
      ),
    );
  }

  Widget _pausedPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3B100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Paused",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: _mmss(ride.moving),
            leftLabel: "Time",
            midValue: ride.avgSpeedKmh.toStringAsFixed(1),
            midLabel: "Avg. speed (km/h)",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance (km)",
          ),
          const SizedBox(height: 14),
          DualButtons(
            leftText: "Resume",
            leftIcon: Icons.play_arrow,
            onLeft: ride.resumePressed,
            rightText: "Stop",
            rightIcon: Icons.stop,
            onRight: ride.stopPressed,
          ),
        ],
      ),
    );
  }

  Widget _autoPausedPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3B100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Auto-paused",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: _mmss(ride.moving),
            leftLabel: "Time",
            midValue: ride.avgSpeedKmh.toStringAsFixed(1),
            midLabel: "Avg. speed (km/h)",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance (km)",
          ),
          const SizedBox(height: 14),
          DualButtons(
            leftText: "Stop",
            leftIcon: Icons.stop,
            onLeft: ride.stopPressed,
            rightText: "Finish",
            rightIcon: Icons.flag,
            onRight: ride.finishPressed,
          ),
        ],
      ),
    );
  }

  Widget _stoppedPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3B100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Stopped",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: _mmss(ride.moving),
            leftLabel: "Time",
            midValue: ride.avgSpeedKmh.toStringAsFixed(1),
            midLabel: "Avg. speed (km/h)",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance (km)",
          ),
          const SizedBox(height: 14),
          DualButtons(
            leftText: "Resume",
            leftIcon: Icons.play_arrow,
            onLeft: ride.resumePressed,
            rightText: "Finish",
            rightIcon: Icons.flag,
            onRight: ride.finishPressed,
          ),
        ],
      ),
    );
  }

  static String _mmss(Duration duration) {
    final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$mm:$ss";
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? badge;
  final VoidCallback onTap;

  const _CircleIcon({
    required this.icon,
    required this.onTap,
    this.label,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    )
                  : Icon(icon, color: Colors.white),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SmallModeButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 110,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF232325),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStartButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BigStartButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}