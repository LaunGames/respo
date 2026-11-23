import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'infra_point.dart';

class PointsRepository {
  static const _assetPath = 'assets/data/points.json';

  Future<List<InfraPoint>> loadPoints() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => InfraPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}