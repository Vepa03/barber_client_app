import 'package:flutter/material.dart';
import '../models/barber_model.dart';
import '../utils/app_theme.dart';

class BarberCard extends StatelessWidget {
  final Barber barber;
  final VoidCallback onTap;

  const BarberCard({super.key, required this.barber, required this.onTap});

  // "10:00:00" → "10:00"
  String _fmtTime(String? t) {
    if (t == null) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    return '${parts[0]}:${parts[1]}';
  }

  bool get _isOpen {
    if (barber.todayClosed || barber.todayOpen == null || barber.todayClose == null) return false;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    int parseMin(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    return nowMin >= parseMin(barber.todayOpen!) && nowMin < parseMin(barber.todayClose!);
  }

  String get _openLabel {
    if (barber.todayClosed || barber.todayClose == null) return 'Closed today';
    if (_isOpen) return 'Open · closes ${_fmtTime(barber.todayClose)}';
    return 'Closed · opens ${_fmtTime(barber.todayOpen)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surf,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover image ────────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: barber.coverImage.isNotEmpty
                      ? Image.network(
                          barber.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 14),

              // ── Info ───────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + distance row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            barber.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Address tags
                    Text(
                      _buildTags(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Open/closed status
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isOpen
                                ? const Color(0xFF27AE60)
                                : AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _openLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isOpen
                                ? const Color(0xFF27AE60)
                                : AppTheme.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rating + price row
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppTheme.accent),
                        const SizedBox(width: 3),
                        Text(
                          barber.rating > 0
                              ? barber.rating.toStringAsFixed(1)
                              : 'New',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (barber.reviewCount > 0) ...[
                          const SizedBox(width: 3),
                          Text(
                            '(${barber.reviewCount})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (barber.minPrice != null)
                          Text(
                            '${barber.minPrice!.toStringAsFixed(0)}+ TMT',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTags() {
    final parts = <String>[];
    parts.add(_venueLabel(barber.venueType));
    if (barber.address.isNotEmpty) parts.add(barber.address);
    return parts.join(' · ');
  }

  Widget _placeholder() {
    return CustomPaint(
      painter: _DiagonalStripePainter(),
      child: const SizedBox.expand(),
    );
  }

  static String _venueLabel(String type) {
    switch (type) {
      case 'womens_salon': return 'Salon';
      case 'massage':      return 'Massage';
      case 'car_wash':     return 'Car Wash';
      default:             return 'Barber';
    }
  }
}

class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = const Color(0xFFEDE8DF);
    final stripe = const Color(0xFFD9D0C4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bg);
    final paint = Paint()..color = stripe..strokeWidth = 8;
    for (double i = -size.height; i < size.width + size.height; i += 18) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
