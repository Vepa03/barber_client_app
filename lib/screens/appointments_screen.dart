import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../services/barber_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import 'barber_profile_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _tab = 0; // 0 = upcoming, 1 = past
  List<AppointmentModel> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AppointmentService.getMyAppointments();
      if (mounted) setState(() { _all = data; _loading = false; });
      _scheduleReminders(data);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleReminders(List<AppointmentModel> appointments) {
    for (final appt in appointments.where((a) => !a.isCompleted && !a.isCancelled)) {
      NotificationService.scheduleReminder(
        appointmentId: appt.id,
        barberName: appt.barber.name,
        scheduledAt: appt.scheduledAt,
      );
    }
  }

  List<AppointmentModel> get _upcoming =>
      _all.where((a) => !a.isCompleted && !a.isCancelled).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<AppointmentModel> get _past =>
      _all.where((a) => a.isCompleted || a.isCancelled).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  Future<void> _cancel(AppointmentModel appt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Randevuyu İptal Et',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('${appt.barber.name} randevunuzu iptal etmek istiyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('İptal Et',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppointmentService.cancel(appt.id);
      NotificationService.cancelReminder(appt.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reschedule(AppointmentModel appt) async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSheet(appointment: appt),
    );
    if (result == null || !mounted) return;
    try {
      await AppointmentService.reschedule(appt.id, result);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _rate(AppointmentModel appt) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RateSheet(
        appointmentId: appt.id,
        barberName: appt.barber.name,
        onSubmitted: _load,
      ),
    );
  }

  Future<void> _directions(AppointmentModel appt) async {
    final query = Uri.encodeComponent('${appt.barber.name}, ${appt.barber.address}');
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openBarber(AppointmentBarberInfo info) async {
    try {
      final barber = await BarberService.getBarberDetail(info.id);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => BarberProfileScreen(barber: barber)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcoming;
    final past = _past;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My bookings',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: context.tp,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!_loading) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${upcoming.length} upcoming · ${past.length} past',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.ts,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Segmented tab ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: context.div,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _TabPill(label: 'Upcoming', selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0)),
                    _TabPill(label: 'Past', selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2.5))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: Builder(builder: (_) {
                        final list = _tab == 0 ? upcoming : past;
                        if (list.isEmpty) return _empty(_tab == 0);
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                          itemCount: list.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _BookingCard(
                              appointment: list[i],
                              canEdit: _tab == 0,
                              onCancel: () => _cancel(list[i]),
                              onReschedule: () => _reschedule(list[i]),
                              onDirections: () => _directions(list[i]),
                              onBarberTap: () => _openBarber(list[i].barber),
                              onRate: () => _rate(list[i]),
                            ),
                          ),
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(bool upcoming) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Text(upcoming ? '📅' : '🗂️',
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                upcoming ? 'Yaklaşan randevunuz yok' : 'Geçmiş randevu yok',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab pill ──────────────────────────────────────────────────────────────────
class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? context.surf : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? context.shadow : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? context.tp : context.ts,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool canEdit;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onDirections;
  final VoidCallback onBarberTap;
  final VoidCallback? onRate;

  const _BookingCard({
    required this.appointment,
    required this.canEdit,
    required this.onCancel,
    required this.onReschedule,
    required this.onDirections,
    required this.onBarberTap,
    this.onRate,
  });

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _dateStr {
    final d = appointment.scheduledAt;
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month]} ${d.day}';
  }

  String get _timeStr {
    final d = appointment.scheduledAt;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get _serviceTitle {
    if (appointment.services.isEmpty) return appointment.barber.name;
    if (appointment.services.length == 1) return appointment.services.first.name;
    return '${appointment.services.first.name} +${appointment.services.length - 1}';
  }

  // Status for display (consider time-based completion)
  String get _effectiveStatus {
    if (appointment.status != 'confirmed') return appointment.status;
    final now = DateTime.now();
    final end = appointment.scheduledAt
        .add(Duration(minutes: appointment.totalDurationMin));
    if (now.isAfter(end)) return 'completed';
    if (now.isAfter(appointment.scheduledAt)) return 'in_progress';
    return 'confirmed';
  }

  @override
  Widget build(BuildContext context) {
    final status = _effectiveStatus;
    final isUpcoming = canEdit && (status == 'confirmed' || status == 'pending');

    return Container(
      decoration: BoxDecoration(
        color: context.surf,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.shadow,
      ),
      child: Column(
        children: [
          // ── Top: icon + title + badge ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VenueIcon(venueType: appointment.barber.venueType),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onBarberTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _serviceTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment.barber.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ],
            ),
          ),

          // ── Dashed divider ─────────────────────────────────────────────────
          _DashedDivider(),

          // ── Date / Time / Price ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _InfoCol(label: 'DATE', value: _dateStr),
                _VerticalDivider(),
                _InfoCol(label: 'TIME', value: _timeStr),
                _VerticalDivider(),
                _InfoCol(
                  label: 'PRICE',
                  value: '${appointment.totalPrice.toStringAsFixed(0)} TMT',
                ),
              ],
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────────────
          if (isUpcoming) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _CardButton(
                      label: 'Reschedule',
                      style: _ButtonStyle.outline,
                      onTap: onReschedule,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardButton(
                      label: 'Cancel',
                      style: _ButtonStyle.outlineRed,
                      onTap: onCancel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardButton(
                      label: 'Directions',
                      style: _ButtonStyle.filled,
                      onTap: onDirections,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (appointment.isCompleted && !appointment.reviewed)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CardButton(
                          label: 'Rate',
                          style: _ButtonStyle.outlineAmber,
                          onTap: onRate ?? () {},
                        ),
                      ),
                    ),
                  Expanded(
                    child: _CardButton(
                      label: 'Directions',
                      style: _ButtonStyle.filled,
                      onTap: onDirections,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Venue Icon ────────────────────────────────────────────────────────────────
class _VenueIcon extends StatelessWidget {
  final String venueType;
  const _VenueIcon({required this.venueType});

  static const _config = {
    'barber':       (icon: Icons.content_cut_rounded,    bg: Color(0xFFFDF0E0), fg: Color(0xFFE8A045)),
    'womens_salon': (icon: Icons.face_retouching_natural, bg: Color(0xFFFCE4EC), fg: Color(0xFFE91E8C)),
    'massage':      (icon: Icons.spa_outlined,            bg: Color(0xFFE8F5E9), fg: Color(0xFF27AE60)),
    'car_wash':     (icon: Icons.local_car_wash_rounded,  bg: Color(0xFFE3F2FD), fg: Color(0xFF2196F3)),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[venueType] ?? _config['barber']!;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(cfg.icon, size: 24, color: cfg.fg),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _label = {
    'pending':     'Pending',
    'confirmed':   'Confirmed',
    'in_progress': 'In Progress',
    'completed':   'Completed',
    'cancelled':   'Cancelled',
    'no_show':     'No Show',
  };
  static const _bg = {
    'pending':     Color(0xFFFFF8E1),
    'confirmed':   Color(0xFFE8F5E9),
    'in_progress': Color(0xFFE3F2FD),
    'completed':   Color(0xFFF3F4F6),
    'cancelled':   Color(0xFFFFEBEE),
    'no_show':     Color(0xFFFFEBEE),
  };
  static const _fg = {
    'pending':     Color(0xFFF59E0B),
    'confirmed':   Color(0xFF27AE60),
    'in_progress': Color(0xFF2196F3),
    'completed':   Color(0xFF6B7280),
    'cancelled':   Color(0xFFEF4444),
    'no_show':     Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg[status] ?? const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label[status] ?? status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _fg[status] ?? AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ── Info Column ───────────────────────────────────────────────────────────────
class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.tt,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.tp)),
        ],
      ),
    );
  }
}

// ── Vertical Divider ──────────────────────────────────────────────────────────
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 36,
      color: context.div,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

// ── Dashed Divider ────────────────────────────────────────────────────────────
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashPainter(color: context.div),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// ── Card Button ───────────────────────────────────────────────────────────────
enum _ButtonStyle { outline, outlineRed, outlineAmber, filled }

class _CardButton extends StatelessWidget {
  final String label;
  final _ButtonStyle style;
  final VoidCallback onTap;
  final bool fullWidth;
  const _CardButton({
    required this.label,
    required this.style,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    switch (style) {
      case _ButtonStyle.filled:
        bg = context.pri; fg = context.isDark ? AppTheme.primary : Colors.white; border = context.pri;
      case _ButtonStyle.outlineRed:
        bg = Colors.transparent; fg = const Color(0xFFEF4444); border = const Color(0xFFEF4444);
      case _ButtonStyle.outlineAmber:
        bg = const Color(0xFFFFF3E0); fg = AppTheme.accent; border = AppTheme.accent;
      case _ButtonStyle.outline:
        bg = Colors.transparent; fg = context.tp; border = context.div;
    }

    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg)),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ── Reschedule Sheet ──────────────────────────────────────────────────────────
class _RescheduleSheet extends StatefulWidget {
  final AppointmentModel appointment;
  const _RescheduleSheet({required this.appointment});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime? _selectedDay;
  String? _selectedSlot;
  Map<String, String> _workingHours = {};
  bool _loadingHours = true;
  bool _loadingSlots = false;
  List<({int startMin, int endMin})> _busyRanges = [];

  static const _dayKeys = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const _months = [
    '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  @override
  void initState() {
    super.initState();
    _loadHours();
  }

  Future<void> _loadHours() async {
    try {
      final detail = await BarberService.getBarberDetail(widget.appointment.barber.id);
      if (mounted) setState(() { _workingHours = detail.workingHours; _loadingHours = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHours = false);
    }
  }

  int get _totalDuration => widget.appointment.totalDurationMin;

  Future<void> _selectDay(DateTime day) async {
    setState(() { _selectedDay = day; _selectedSlot = null; _busyRanges = []; _loadingSlots = true; });
    try {
      final ranges = await BarberService.getBusySlots(widget.appointment.barber.id, day);
      final apptStart = widget.appointment.scheduledAt.toLocal();
      final apptStartMin = apptStart.hour * 60 + apptStart.minute;
      final filtered = ranges
          .where((r) => !(r.startMin == apptStartMin && r.endMin == apptStartMin + _totalDuration))
          .toList();
      if (mounted) setState(() { _busyRanges = filtered; _loadingSlots = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  bool _isSlotBusy(String slot) {
    final parts = slot.split(':');
    final slotStart = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final slotEnd = slotStart + _totalDuration;
    return _busyRanges.any((r) => slotStart < r.endMin && slotEnd > r.startMin);
  }

  List<DateTime> get _days {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return List.generate(60, (i) => tomorrow.add(Duration(days: i)));
  }

  bool _isClosed(DateTime day) {
    final info = _workingHours[_dayKeys[day.weekday - 1]];
    return info == null || info == 'Closed';
  }

  List<String> _slots(DateTime day) {
    final info = _workingHours[_dayKeys[day.weekday - 1]];
    if (info == null || info == 'Closed') return [];
    final parts = info.split('–');
    if (parts.length < 2) return [];
    final open = _parseTime(parts[0].trim());
    final close = _parseTime(parts[1].trim());
    if (open == null || close == null) return [];
    final slots = <String>[];
    var cur = open.hour * 60 + open.minute;
    final end = close.hour * 60 + close.minute;
    while (cur + _totalDuration <= end) {
      slots.add('${(cur ~/ 60).toString().padLeft(2, '0')}:${(cur % 60).toString().padLeft(2, '0')}');
      cur += _totalDuration;
    }
    return slots;
  }

  TimeOfDay? _parseTime(String s) {
    final p = s.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void _confirm() {
    if (_selectedDay == null || _selectedSlot == null) return;
    final parts = _selectedSlot!.split(':');
    Navigator.pop(context, DateTime(
      _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
      int.parse(parts[0]), int.parse(parts[1]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Randevuyu Düzenle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Yeni tarih ve saat seç',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          if (_loadingHours)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2.5)),
            )
          else ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _days.length,
                itemBuilder: (_, i) {
                  final day = _days[i];
                  final closed = _isClosed(day);
                  final selected = _selectedDay?.day == day.day && _selectedDay?.month == day.month;
                  return GestureDetector(
                    onTap: closed ? null : () => _selectDay(day),
                    child: Container(
                      width: 52,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: selected ? context.pri : closed ? context.bg : context.surf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? context.pri : context.div),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_dayLabels[day.weekday - 1],
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: selected ? (context.isDark ? AppTheme.primary : Colors.white) : closed ? context.tt : context.ts)),
                          const SizedBox(height: 4),
                          Text('${day.day}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                  color: selected ? (context.isDark ? AppTheme.primary : Colors.white) : closed ? context.tt : context.tp)),
                          Text(_months[day.month],
                              style: TextStyle(fontSize: 9,
                                  color: selected ? Colors.white70 : context.tt)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Saat Seç',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 10),
              if (_loadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2.5)),
                )
              else
                SizedBox(
                  height: 44,
                  child: Builder(builder: (_) {
                    final available = _slots(_selectedDay!).where((s) => !_isSlotBusy(s)).toList();
                    if (available.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Bu gün için uygun saat yok',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      );
                    }
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: available.map((slot) {
                        final sel = _selectedSlot == slot;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? context.pri : context.surf,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: sel ? context.pri : context.div),
                            ),
                            child: Text(slot,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: sel ? (context.isDark ? AppTheme.primary : Colors.white) : context.tp)),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: (_selectedDay != null && _selectedSlot != null) ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.divider,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Güncelle',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Rate Sheet (from Appointments screen) ─────────────────────────────────────
class _RateSheet extends StatefulWidget {
  final String appointmentId;
  final String barberName;
  final VoidCallback onSubmitted;
  const _RateSheet({
    required this.appointmentId,
    required this.barberName,
    required this.onSubmitted,
  });

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    try {
      await AppointmentService.review(
        widget.appointmentId,
        rating: _rating,
        comment: _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      widget.onSubmitted();
      messenger.showSnackBar(SnackBar(
        content: const Text('Yorumunuz gönderildi 🎉'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: context.surf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Deneyimini Değerlendir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(widget.barberName,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 42,
                    color: star <= _rating ? AppTheme.starColor : AppTheme.textTertiary,
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 8),
            Text(['', 'Berbat 😞', 'Kötü 😐', 'İyi 👍', 'Harika 😊', 'Mükemmel 🤩'][_rating],
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Yorum yaz (isteğe bağlı)',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: (_rating > 0 && !_submitting) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.divider,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Gönder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
