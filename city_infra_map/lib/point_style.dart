import 'package:flutter/material.dart';

class PointStyle {
  static IconData iconFor(String type) => switch (type) {
        'school' => Icons.school,
        'hospital' => Icons.local_hospital,
        'park' => Icons.park,
        'transport' => Icons.directions_subway,
        'university' => Icons.cast_for_education,
        _ => Icons.place,
      };

  static Color colorFor(String type) => switch (type) {
        'school' => Colors.blue,
        'hospital' => Colors.red,
        'park' => Colors.green,
        'transport' => Colors.purple,
        'university' => Colors.orange,
        _ => Colors.grey,
      };
}