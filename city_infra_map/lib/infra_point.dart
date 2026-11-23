import 'package:latlong2/latlong.dart';

class InfraPoint {
  final String id;
  final String name;
  final String type;
  final String address;
  final LatLng position;

  const InfraPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.position,
  });

  factory InfraPoint.fromJson(Map<String, dynamic> json) {
    return InfraPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
    );
  }
}