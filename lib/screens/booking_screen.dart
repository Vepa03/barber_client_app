import 'package:flutter/material.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';
import '../services/appointment_service.dart';
import '../services/barber_service.dart';
import '../utils/app_theme.dart';
import 'appointments_screen.dart';

class BookingScreen extends StatefulWidget {
  final Barber barber;
  final Set<String> selectedServiceIds;

  const BookingScreen({
    super.key,
    required this.barber,
    required this.selectedServiceIds,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDay;
  String?   _selectedSlot;
  bool      _isBooking    = false;
  bool      _loadingSlots = false;
  List<({int startMin, int endMin})> _busyRanges = [];

  // Days-of-week index → working hours key
  static const _dayKeys = [
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday',
  ];
  static const _dayLabels = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
  static const _monthNames = [
    '','Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara',
  ];

  List<ServiceModel> get _selectedServices => widget.barber.services
      .where((s) => widget.selectedServiceIds.contains(s.id))
      .toList();

  double get _total =>
      _selectedServices.fold(0, (sum, s) => sum + s.price);

  int get _totalDuration =>
      _selectedServices.fold(0, (sum, s) {
        final mins = int.tryParse(
            RegExp(r'(\d+)\s*min').firstMatch(s.duration)?.group(1) ?? '30') ?? 30;
        return sum + mins;
      });

  // Generate next 60 days starting tomorrow
  List<DateTime> get _days {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return List.generate(60, (i) => tomorrow.add(Duration(days: i)));
  }

  bool _isClosed(DateTime day) {
    final key  = _dayKeys[day.weekday - 1];
    final info = widget.barber.workingHours[key];
    return info == null || info == 'Closed';
  }

  List<String> _slotsForDay(DateTime day) {
    final key  = _dayKeys[day.weekday - 1];
    final info = widget.barber.workingHours[key];
    if (info == null || info == 'Closed') return [];

    // parse "09:00 – 20:00"
    final parts = info.split('–');
    if (parts.length < 2) return [];
    final open  = _parseTime(parts[0].trim());
    final close = _parseTime(parts[1].trim());
    if (open == null || close == null) return [];

    final slots      = <String>[];
    var   cur        = open.hour * 60 + open.minute;
    final closeTotal = close.hour * 60 + close.minute;

    while (cur + _totalDuration <= closeTotal) {
      final h = cur ~/ 60;
      final m = cur  % 60;
      slots.add('${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}');
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

  Future<void> _selectDay(DateTime day) async {
    setState(() {
      _selectedDay  = day;
      _selectedSlot = null;
      _busyRanges   = [];
      _loadingSlots = true;
    });
    try {
      final ranges = await BarberService.getBusySlots(widget.barber.id, day);
      if (mounted) setState(() { _busyRanges = ranges; _loadingSlots = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  bool _isSlotBusy(String slot) {
    final parts    = slot.split(':');
    final slotStart = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final slotEnd   = slotStart + _totalDuration;
    for (final r in _busyRanges) {
      if (slotStart < r.endMin && slotEnd > r.startMin) return true;
    }
    return false;
  }

  Future<void> _confirmBooking() async {
    if (_selectedDay == null || _selectedSlot == null) return;
    setState(() => _isBooking = true);

    final slot  = _selectedSlot!.split(':');
    final dt    = DateTime(
      _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
      int.parse(slot[0]), int.parse(slot[1]),
    );

    try {
      await AppointmentService.book(
        barberId:   widget.barber.id,
        serviceIds: widget.selectedServiceIds.toList(),
        scheduledAt: dt,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Randevunuz alındı! 🎉'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Pop this screen + barber profile, then go to appointments
      Navigator.popUntil(context, (r) => r.isFirst);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
      );
    } catch (e) {
      setState(() => _isBooking = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Randevu Al'),
        backgroundColor: AppTheme.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                _buildBarberCard(),
                const SizedBox(height: 20),
                _buildServicesCard(),
                const SizedBox(height: 24),
                _buildCalendar(),
                if (_selectedDay != null) ...[
                  const SizedBox(height: 24),
                  _buildTimeSlots(),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Barber card ─────────────────────────────────────────────────────────────
  Widget _buildBarberCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.barber.coverImage.isNotEmpty
                ? Image.network(widget.barber.coverImage,
                    width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52, height: 52,
                    color: AppTheme.divider,
                    child: const Icon(Icons.store_rounded,
                        color: AppTheme.textTertiary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.barber.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(widget.barber.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Services summary ─────────────────────────────────────────────────────────
  Widget _buildServicesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seçilen Hizmetler',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ..._selectedServices.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(s.icon,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary)),
                    ),
                    Text('₺${s.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Calendar ─────────────────────────────────────────────────────────────────
  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gün Seçin',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final day    = _days[i];
              final closed = _isClosed(day);
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year  == day.year  &&
                  _selectedDay!.month == day.month &&
                  _selectedDay!.day   == day.day;

              return GestureDetector(
                onTap: closed ? null : () => _selectDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : closed
                            ? AppTheme.divider.withOpacity(0.5)
                            : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.divider,
                    ),
                    boxShadow: isSelected ? AppTheme.cardShadow : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayLabels[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white70
                              : closed
                                  ? AppTheme.textTertiary
                                  : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : closed
                                  ? AppTheme.textTertiary
                                  : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _monthNames[day.month],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white60
                              : closed
                                  ? AppTheme.textTertiary
                                  : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Time slots ───────────────────────────────────────────────────────────────
  Widget _buildTimeSlots() {
    if (_loadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 2.5),
        ),
      );
    }

    final allSlots      = _slotsForDay(_selectedDay!);
    final availableSlots = allSlots.where((s) => !_isSlotBusy(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saat Seçin',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        if (availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Bu gün için uygun saat yok',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableSlots.map((slot) {
              final isSelected = slot == _selectedSlot;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.divider,
                    ),
                    boxShadow: isSelected ? AppTheme.cardShadow : [],
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final canBook = _selectedDay != null && _selectedSlot != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₺${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '$_totalDuration dakika',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Book button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: canBook && !_isBooking ? _confirmBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canBook ? AppTheme.primary : AppTheme.divider,
                foregroundColor:
                    canBook ? Colors.white : AppTheme.textTertiary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Randevuyu Onayla',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
