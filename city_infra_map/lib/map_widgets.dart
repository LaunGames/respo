import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'infra_point.dart';
import 'point_style.dart';

class PinMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;

  const PinMarker({
    super.key,
    required this.color,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isSelected ? 48.0 : 36.0;
    final double iconSize = isSelected ? 26.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                blurRadius: isSelected ? 14 : 8,
                color: isSelected
                    ? color.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
        CustomPaint(
          size: Size(isSelected ? 14 : 10, isSelected ? 10 : 7),
          painter: _PinTailPainter(color: color),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

class ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const ZoomButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

// ===== КРАСИВЫЙ ЗАГОЛОВОК =====
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_city, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Челябинск',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'инфраструктура',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.tealAccent : Colors.teal.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== СВОРАЧИВАЕМОЕ ВЕРТИКАЛЬНОЕ МЕНЮ ФИЛЬТРОВ =====
class FilterMenu extends StatefulWidget {
  final String? activeFilter;
  final ValueChanged<String?> onFilterChanged;

  const FilterMenu({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  State<FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<FilterMenu> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _select(String? type) {
    widget.onFilterChanged(type);
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingActionButton(
          heroTag: 'filter_menu_btn',
          mini: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          onPressed: _toggle,
          child: Icon(
            _isOpen ? Icons.close : Icons.tune,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _animation.value,
                child: Opacity(
                  opacity: _animation.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _menuItem('Все', null),
              const SizedBox(height: 6),
              _menuItem('Школы', 'school'),
              const SizedBox(height: 6),
              _menuItem('Больницы', 'hospital'),
              const SizedBox(height: 6),
              _menuItem('Парки', 'park'),
              const SizedBox(height: 6),
              _menuItem('Транспорт', 'transport'),
              const SizedBox(height: 6),
              _menuItem('Вузы и колледжи', 'university'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(String label, String? type) {
    final isSelected = widget.activeFilter == type;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _select(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary
                : scheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(type),
                size: 18,
                color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String? type) {
    return switch (type) {
      'school' => Icons.school,
      'hospital' => Icons.local_hospital,
      'park' => Icons.park,
      'transport' => Icons.directions_subway,
      'university' => Icons.cast_for_education,
      _ => Icons.apps,
    };
  }
}

class RouteInfoCard extends StatelessWidget {
  final double distance;
  final double duration;

  const RouteInfoCard({
    super.key,
    required this.distance,
    required this.duration,
  });

  String get _formatDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} км';
    }
    return '${distance.toInt()} м';
  }

  String _formatDuration() {
    final mins = (duration / 60).round();
    if (mins >= 60) {
      return '${mins ~/ 60} ч ${mins % 60} мин';
    }
    return '$mins мин';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDuration(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDistance,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}