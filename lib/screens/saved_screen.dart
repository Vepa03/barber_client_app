import 'package:flutter/material.dart';
import '../models/barber_model.dart';
import '../services/saved_barbers_service.dart';
import '../utils/app_theme.dart';
import '../widgets/barber_card.dart';
import 'barber_profile_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Barber> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await SavedBarbersService.getSaved();
    if (mounted) setState(() { _saved = list; _loading = false; });
  }

  Future<void> _unsave(Barber barber) async {
    await SavedBarbersService.unsave(barber.id);
    setState(() => _saved.removeWhere((b) => b.id == barber.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Kaydedilenler',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2.5))
          : _saved.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: _saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final barber = _saved[i];
                      return Dismissible(
                        key: Key(barber.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.favorite_border_rounded,
                              color: Colors.redAccent, size: 24),
                        ),
                        onDismissed: (_) => _unsave(barber),
                        child: BarberCard(
                          barber: barber,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              _route(BarberProfileScreen(barber: barber)),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤍', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text('Henüz kayıtlı berber yok',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Berberlere göz at ve kalbe bas!',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );

  PageRoute _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );
}
