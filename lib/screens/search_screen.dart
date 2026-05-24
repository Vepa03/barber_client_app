import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';
import '../services/barber_service.dart';
import '../utils/app_theme.dart';
import '../widgets/barber_card.dart';
import 'barber_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

const _kCategories = [
  (type: null,           label: 'All'),
  (type: 'womens_salon', label: 'Salon'),
  (type: 'barber',       label: 'Berber'),
  (type: 'car_wash',     label: 'Car Wash'),
  (type: 'massage',      label: 'Massage'),
];

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus      = FocusNode();
  String  _query    = '';
  String? _venueType;
  List<Barber> _results   = [];
  List<String> _recents   = [];
  bool _loading = false;
  bool _searched = false;

  static const _recentsKey = 'search_recents';

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recents = prefs.getStringList(_recentsKey) ?? []);
  }

  Future<void> _saveRecent(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = [q, ..._recents.where((r) => r != q)].take(8).toList();
    await prefs.setStringList(_recentsKey, list);
    setState(() => _recents = list);
  }

  Future<void> _removeRecent(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _recents.where((r) => r != q).toList();
    await prefs.setStringList(_recentsKey, list);
    setState(() => _recents = list);
  }

  Future<void> _search({String? query, String? venueType}) async {
    final q = (query ?? _query).trim();
    final vt = venueType ?? _venueType;
    setState(() { _loading = true; _searched = true; });
    try {
      final results = await BarberService.getBarbers(
        search: q.isNotEmpty ? q : null,
        venueType: vt,
      );
      if (mounted) setState(() { _results = results; _loading = false; });
      if (q.isNotEmpty) _saveRecent(q);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSubmit(String val) {
    if (val.trim().isEmpty) return;
    _search(query: val.trim());
    _focus.unfocus();
  }

  void _selectCategory(String? type) {
    setState(() => _venueType = type);
    _search(venueType: type);
  }

  void _tapRecent(String q) {
    _controller.text = q;
    setState(() => _query = q);
    _search(query: q);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: context.surf,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: context.shadow,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search_rounded,
                        size: 20, color: context.tt),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: (v) => setState(() => _query = v),
                        onSubmitted: _onSubmit,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(
                            fontSize: 15,
                            color: context.tp,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Salon, berber, car wash, massage...',
                          hintStyle: TextStyle(
                              color: context.tt,
                              fontSize: 14,
                              fontWeight: FontWeight.w400),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() { _query = ''; _searched = false; _results = []; });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.cancel_rounded,
                              size: 18, color: context.tt),
                        ),
                      )
                    else
                      const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Category pills ───────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _kCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _kCategories[i];
                  final selected = _venueType == cat.type;
                  return GestureDetector(
                    onTap: () => _selectCategory(cat.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFB85C2A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFB85C2A)
                              : context.div,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : context.ts,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2.5))
                  : !_searched
                      ? _buildInitial()
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial() {
    if (_recents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('Start searching',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Text(
          'RECENT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recents.map((r) => _RecentChip(
            label: r,
            onTap: () => _tapRecent(r),
            onRemove: () => _removeRecent(r),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('😕', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('No results found',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_results.length} shops',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          );
        }
        final b = _results[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: BarberCard(
            barber: b,
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => BarberProfileScreen(barber: b),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Recent Chip ───────────────────────────────────────────────────────────────
class _RecentChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _RecentChip(
      {required this.label, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.surf,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.div, width: 1.5),
          boxShadow: context.shadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.tp,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded,
                  size: 14, color: context.tt),
            ),
          ],
        ),
      ),
    );
  }
}
