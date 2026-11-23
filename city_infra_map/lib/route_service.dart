import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RouteService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving/';

  Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      '$_baseUrl${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );
    
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('OSRM HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw Exception(data['message'] ?? 'Route error');
    }

    final route = data['routes'][0];
    final coords = route['geometry']['coordinates'] as List;
    final points = coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    return RouteResult(
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }
}