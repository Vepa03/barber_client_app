import 'package:flutter/material.dart';
import '../models/barber_model.dart';
import '../services/barber_service.dart';
import '../utils/app_theme.dart';
import '../widgets/barber_card.dart';
import 'barber_profile_screen.dart';
import 'category_screen.dart';
import 'customer_profile_screen.dart';
import 'appointments_screen.dart';
import 'notifications_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? initialVenueType;
  const HomeScreen({super.key, this.initialVenueType});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _SortMode { recommended, topRated, price, nearest }

const _kVenueConfig = {
  'barber':       (label: 'Barber',    title: 'Barber',    color: Color(0xFFB85C2A), bg: Color(0xFFF5EDE3), icon: Icons.content_cut_rounded),
  'womens_salon': (label: 'Salon',     title: 'Salon',     color: Color(0xFFB85C2A), bg: Color(0xFFF5EDE3), icon: Icons.face_retouching_natural),
  'massage':      (label: 'Massage',   title: 'Massage',   color: Color(0xFF2E7D5E), bg: Color(0xFFE8F5EF), icon: Icons.spa_outlined),
  'car_wash':     (label: 'Car Wash',  title: 'Car Wash',  color: Color(0xFF1A5276), bg: Color(0xFFE3EEF5), icon: Icons.local_car_wash_rounded),
};

const _kDefaultConfig = (label: 'All', title: 'All Services', color: Color(0xFFB85C2A), bg: Color(0xFFF5EDE3), icon: Icons.storefront_rounded);

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCity     = 'Istanbul';
  String _selectedCitySlug = 'istanbul';
  String _searchQuery      = '';
  int    _selectedNavIndex = 0;
  _SortMode _sortMode      = _SortMode.recommended;
  late String? _selectedVenueType;

  List<Map<String, String>> _cities = [
    {'id': '', 'name': 'Istanbul', 'slug': 'istanbul'},
    {'id': '', 'name': 'Ankara',   'slug': 'ankara'},
    {'id': '', 'name': 'Izmir',    'slug': 'izmir'},
  ];
  List<Barber> _barbers  = [];
  bool _isLoading        = true;

  @override
  void initState() {
    super.initState();
    _selectedVenueType = widget.initialVenueType;
    _loadCities();
    _loadBarbers();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await BarberService.getCities();
      if (mounted) setState(() => _cities = cities);
    } catch (_) {}
  }

  Future<void> _loadBarbers() async {
    setState(() => _isLoading = true);
    try {
      final barbers = await BarberService.getBarbers(
        citySlug: _selectedCitySlug,
        venueType: _selectedVenueType,
      );
      if (mounted) setState(() { _barbers = barbers; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Barber> get _sortedBarbers {
    var list = _barbers.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
             b.address.toLowerCase().contains(q);
    }).toList();

    switch (_sortMode) {
      case _SortMode.recommended:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.topRated:
        list = list.where((b) => b.rating >= 4.0).toList();
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.price:
        list.sort((a, b) {
          final pa = a.minPrice ?? double.infinity;
          final pb = b.minPrice ?? double.infinity;
          return pa.compareTo(pb);
        });
      case _SortMode.nearest:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CityPickerSheet(
        selectedCity: _selectedCity,
        cities: _cities.map((c) => c['name']!).toList(),
        onSelected: (city) {
          final match = _cities.firstWhere(
            (c) => c['name'] == city,
            orElse: () => {'name': city, 'slug': city.toLowerCase()},
          );
          setState(() {
            _selectedCity     = city;
            _selectedCitySlug = match['slug']!;
          });
          Navigator.pop(ctx);
          _loadBarbers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _selectedVenueType != null
        ? (_kVenueConfig[_selectedVenueType] ?? _kDefaultConfig)
        : _kDefaultConfig;
    final sorted = _sortedBarbers;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: context.surf,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: context.shadow,
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: context.tp),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      cfg.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.tp,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // Notification icon
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: context.surf,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: context.shadow,
                      ),
                      child: Icon(Icons.notifications_none_rounded,
                          size: 22, color: context.tp),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Hero banner ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: cfg.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cfg.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cfg.color.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cfg.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: cfg.color,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showCityPicker,
                            child: Row(
                              children: [
                                Text(
                                  '${sorted.length} shops · $_selectedCity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cfg.color.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: cfg.color.withValues(alpha: 0.65)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(cfg.icon, size: 52,
                        color: cfg.color.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Filter pills ────────────────────────────────────────────────
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _SortPill(
                    label: 'Recommended',
                    selected: _sortMode == _SortMode.recommended,
                    onTap: () => setState(() => _sortMode = _SortMode.recommended),
                  ),
                  const SizedBox(width: 8),
                  _SortPill(
                    label: 'Top rated',
                    selected: _sortMode == _SortMode.topRated,
                    onTap: () => setState(() => _sortMode = _SortMode.topRated),
                  ),
                  const SizedBox(width: 8),
                  _SortPill(
                    label: 'Price',
                    selected: _sortMode == _SortMode.price,
                    onTap: () => setState(() => _sortMode = _SortMode.price),
                  ),
                  const SizedBox(width: 8),
                  _SortPill(
                    label: 'Nearest',
                    selected: _sortMode == _SortMode.nearest,
                    onTap: () => setState(() => _sortMode = _SortMode.nearest),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2.5))
                  : sorted.isEmpty
                      ? _buildEmpty(cfg.title)
                      : RefreshIndicator(
                          onRefresh: _loadBarbers,
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            itemCount: sorted.length + 1,
                            separatorBuilder: (_, i) =>
                                i == 0 ? const SizedBox() : const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    'AVAILABLE',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textTertiary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                );
                              }
                              final b = sorted[i - 1];
                              return BarberCard(
                                barber: b,
                                onTap: () => Navigator.push(
                                  context,
                                  _slideRoute(BarberProfileScreen(barber: b)),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildEmpty(String category) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('$_selectedCity\'de $category bulunamadı',
              style: AppTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Farklı bir şehir deneyin',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.surf,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: context.div,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                },
                style: TextStyle(fontSize: 15, color: context.tp),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: context.tt, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: context.bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (icon: Icons.home_rounded,          label: 'Home'),
      (icon: Icons.search_rounded,        label: 'Search'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.person_rounded,         label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.surf,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = i == _selectedNavIndex;
              return GestureDetector(
                onTap: () {
                  if (i == 1) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const SearchScreen()));
                  } else if (i == 2) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const AppointmentsScreen()));
                  } else if (i == 3) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CustomerProfileScreen()));
                  } else {
                    setState(() => _selectedNavIndex = i);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].icon,
                      size: 24,
                      color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}

// ── Sort Pill ─────────────────────────────────────────────────────────────────
class _SortPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB85C2A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFB85C2A) : context.div,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.ts,
          ),
        ),
      ),
    );
  }
}

// ── City Picker ───────────────────────────────────────────────────────────────
class _CityPickerSheet extends StatelessWidget {
  final String selectedCity;
  final List<String> cities;
  final void Function(String) onSelected;
  const _CityPickerSheet({
    required this.selectedCity,
    required this.cities,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Container(
        decoration: BoxDecoration(
          color: context.surf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: context.div,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select City', style: AppTheme.titleLarge),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...cities.map((city) {
                    final isSelected = city == selectedCity;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                      title: Text(city,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? context.tp : context.ts,
                          )),
                      trailing: isSelected
                          ? Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(
                                color: AppTheme.accent, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white))
                          : null,
                      onTap: () => onSelected(city),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
