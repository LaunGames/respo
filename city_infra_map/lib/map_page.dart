import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster_2/flutter_map_marker_cluster.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'infra_point.dart';
import 'map_widgets.dart';
import 'point_style.dart';
import 'points_repository.dart';
import 'route_service.dart';

class MapPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MapPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LatLng _center = const LatLng(55.1600, 61.4000);
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final PointsRepository _repository = PointsRepository();
  final RouteService _routeService = RouteService();

  final Stream<LocationMarkerPosition?> _positionStream =
      const LocationMarkerDataStreamFactory().fromGeolocatorPositionStream();

  StreamSubscription<LocationMarkerPosition?>? _positionSubscription;

  List<InfraPoint> _allPoints = [];
  bool _loading = true;
  String? _activeFilter;
  String _searchQuery = '';

  RouteResult? _currentRoute;
  bool _routeLoading = false;
  LatLng? _currentLocation;

  LatLng? _routeStart;
  LatLng? _routeEnd;
  InfraPoint? _selectedPoint;

  Set<String> _favoriteIds = {};
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _loadFavorites();
    _positionSubscription = _positionStream.listen((pos) {
      if (pos != null) {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favoriteIds = saved.toSet();
    });
  }

  Future<void> _toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    await prefs.setStringList('favorites', _favoriteIds.toList());
  }

  Future<void> _loadPoints() async {
    try {
      final points = await _repository.loadPoints();
      if (!mounted) return;
      setState(() {
        _allPoints = points;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  List<InfraPoint> get _filtered {
    var result = _allPoints;

    if (_showOnlyFavorites) {
      result = result.where((p) => _favoriteIds.contains(p.id)).toList();
    }

    if (_activeFilter != null) {
      result = result.where((p) => p.type == _activeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.address.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  List<Marker> _buildMarkers() {
    return _filtered.map((p) {
      final isSelected = _selectedPoint?.id == p.id;
      final isFav = _favoriteIds.contains(p.id);

      return Marker(
        point: p.position,
        width: isSelected ? 56 : 44,
        height: isSelected ? 66 : 52,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showInfo(p),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PinMarker(
                  color: PointStyle.colorFor(p.type),
                  icon: PointStyle.iconFor(p.type),
                  isSelected: isSelected),
              if (isFav)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: Colors.amber, size: 16),
                  ),
                )
            ],
          ),
        ),
      );
    }).toList();
  }

  void _flyTo(InfraPoint point) {
    _mapController.move(point.position, 15);
  }

  void _zoomIn() => _mapController.move(
      _mapController.camera.center,
      (_mapController.camera.zoom + 1).clamp(3.0, 18.0));
  void _zoomOut() => _mapController.move(
      _mapController.camera.center,
      (_mapController.camera.zoom - 1).clamp(3.0, 18.0));

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ожидание координат GPS…')),
      );
    }
  }

  Future<void> _buildRoute(InfraPoint destination) async {
    final startPos = _currentLocation ?? _mapController.camera.center;
    setState(() {
      _routeLoading = true;
      _routeStart = startPos;
      _routeEnd = destination.position;
    });
    try {
      final route = await _routeService.getRoute(startPos, destination.position);
      if (!mounted) return;
      setState(() {
        _currentRoute = route;
        _routeLoading = false;
      });
      _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.points),
          padding: const EdgeInsets.all(50)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
        _routeStart = null;
        _routeEnd = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Маршрут не найден: $e')));
    }
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _routeStart = null;
      _routeEnd = null;
    });
  }

  void _showObjectsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (q) {
                      setState(() => _searchQuery = q);
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Ничего не найдено'))
                      : ListView.builder(
                          controller: controller,
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final p = _filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    PointStyle.colorFor(p.type).withValues(alpha: 0.2),
                                child: Icon(PointStyle.iconFor(p.type),
                                    color: PointStyle.colorFor(p.type), size: 20),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(p.address),
                              onTap: () {
                                Navigator.pop(context);
                                _flyTo(p);
                                _showInfo(p);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInfo(InfraPoint p) {
    setState(() => _selectedPoint = p);
    final isFav = _favoriteIds.contains(p.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          PointStyle.colorFor(p.type).withValues(alpha: 0.2),
                      child: Icon(PointStyle.iconFor(p.type),
                          color: PointStyle.colorFor(p.type), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Тип: ${p.type}',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: isFav ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                      onPressed: () {
                        _toggleFavorite(p.id);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Адрес: ${p.address}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('Маршрут', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      Navigator.pop(context);
                      _buildRoute(p);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 12,
                    minZoom: 3,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    // ===== ДИНАМИЧЕСКАЯ КАРТА (OSM + ИНВЕРСИЯ ДЛЯ ТЕМНОЙ ТЕМЫ) =====
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.city_infra_map',
                      maxNativeZoom: 19,
                      tileBuilder: isDark
                          ? (context, tileWidget, tile) {
                              return ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  -0.2126, -0.7152, -0.0722, 0, 255,
                                  -0.2126, -0.7152, -0.0722, 0, 255,
                                  -0.2126, -0.7152, -0.0722, 0, 255,
                                  0,       0,       0,       1, 0,
                                ]),
                                child: tileWidget,
                              );
                            }
                          : null,
                    ),
                    CurrentLocationLayer(
                      positionStream: _positionStream,
                      alignPositionOnUpdate: AlignOnUpdate.never,
                      style: LocationMarkerStyle(
                        marker: const DefaultLocationMarker(
                          color: Colors.blue,
                          child: Icon(Icons.circle, color: Colors.white, size: 12),
                        ),
                        markerSize: const Size(20, 20),
                        accuracyCircleColor: Colors.blue.withValues(alpha: 0.1),
                        headingSectorColor: Colors.blue.withValues(alpha: 0.2),
                        headingSectorRadius: 20,
                      ),
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 60,
                        size: const Size(40, 40),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(50),
                        maxZoom: 16,
                        markers: _buildMarkers(),
                        builder: (context, markers) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.teal, Colors.tealAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_currentRoute != null)
                      PolylineLayer(
                          polylines: [
                            Polyline(
                                points: _currentRoute!.points,
                                color: Colors.blue,
                                strokeWidth: 5.0)
                          ]),
                    if (_routeStart != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _routeStart!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.trip_origin,
                                color: Colors.green, size: 30),
                          ),
                        ],
                      ),
                    if (_routeEnd != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _routeEnd!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.flag,
                                color: Colors.red, size: 30),
                          ),
                        ],
                      ),
                  ],
                ),

                Positioned(
                  top: topInset + 10,
                  left: 16,
                  child: const AppTitle(),
                ),

                Positioned(
                  top: topInset + 10,
                  right: 16,
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        onPressed: widget.onToggleTheme,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: _showOnlyFavorites ? Icons.star : Icons.star_border,
                        color: _showOnlyFavorites ? Colors.amber : null,
                        onPressed: () =>
                            setState(() => _showOnlyFavorites = !_showOnlyFavorites),
                      ),
                      if (_currentRoute != null) ...[
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.close,
                          onPressed: _clearRoute,
                        ),
                      ],
                    ],
                  ),
                ),

                Positioned(
                  top: topInset + 70,
                  left: 16,
                  child: FilterMenu(
                    activeFilter: _activeFilter,
                    onFilterChanged: (type) =>
                        setState(() => _activeFilter = type),
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      ZoomButton(
                          icon: Icons.my_location,
                          onTap: _centerOnCurrentLocation),
                      const SizedBox(height: 8),
                      ZoomButton(icon: Icons.add, onTap: _zoomIn),
                      const SizedBox(height: 8),
                      ZoomButton(icon: Icons.remove, onTap: _zoomOut),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _showObjectsList,
                        child: const Icon(Icons.list),
                      ),
                    ],
                  ),
                ),

                if (_currentRoute != null && !_routeLoading)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 100,
                    child: RouteInfoCard(
                      distance: _currentRoute!.distanceMeters,
                      duration: _currentRoute!.durationSeconds,
                    ),
                  ),
                if (_routeLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
        tooltip: '',
      ),
    );
  }
}