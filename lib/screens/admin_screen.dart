import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _approved = [];
  List<Map<String, dynamic>> _rejected = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await ApiClient.get('/admin/barbers') as List<dynamic>;
      final all = data.cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _pending =
              all.where((b) => b['status'] == 'pending').toList();
          _approved =
              all.where((b) => b['status'] == 'approved').toList();
          _rejected =
              all.where((b) => b['status'] == 'rejected').toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> barber) async {
    final id = barber['id'] as String;
    try {
      await ApiClient.patch('/admin/barbers/$id/approve', {});
      if (!mounted) return;
      setState(() {
        _pending.removeWhere((b) => b['id'] == id);
        _approved.add({...barber, 'status': 'approved'});
      });
      _showSnack('✅ Onaylandı: ${barber['firstName']} ${barber['lastName']}',
          Colors.green.shade700);
    } catch (e) {
      if (mounted) _showSnack(e.toString(), Colors.redAccent);
    }
  }

  Future<void> _reject(Map<String, dynamic> barber) async {
    final id = barber['id'] as String;
    try {
      await ApiClient.patch('/admin/barbers/$id/reject', {});
      if (!mounted) return;
      setState(() {
        _pending.removeWhere((b) => b['id'] == id);
        _rejected.add({...barber, 'status': 'rejected'});
      });
      _showSnack('❌ Reddedildi: ${barber['firstName']} ${barber['lastName']}',
          AppTheme.textSecondary);
    } catch (e) {
      if (mounted) _showSnack(e.toString(), Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(Icons.admin_panel_settings_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Admin Paneli'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
            tooltip: 'Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bekleyenler'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Badge(count: _pending.length, color: AppTheme.warning),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Onaylananlar'),
            const Tab(text: 'Reddedilenler'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2.5))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pending, showActions: true),
                _buildList(_approved, showActions: false),
                _buildList(_rejected, showActions: false),
              ],
            ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> list, {
    required bool showActions,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              showActions ? '🎉' : '📭',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              showActions
                  ? 'Bekleyen istek yok'
                  : 'Bu listede kimse yok',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _BarberRequestCard(
          barber: list[i],
          showActions: showActions,
          onApprove: () => _approve(list[i]),
          onReject: () => _confirmReject(list[i]),
        ),
      ),
    );
  }

  Future<void> _confirmReject(Map<String, dynamic> barber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reddet?',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        content: Text(
          '${barber['firstName']} ${barber['lastName']} adlı berberin başvurusunu reddetmek istediğine emin misin?',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reddet',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) _reject(barber);
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

// ── Barber Request Card ───────────────────────────────────────────────────────
class _BarberRequestCard extends StatelessWidget {
  final Map<String, dynamic> barber;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _BarberRequestCard({
    required this.barber,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = (barber['firstName'] as String?) ?? '';
    final lastName = (barber['lastName'] as String?) ?? '';
    final phone = (barber['phone'] as String?) ?? '';
    final salonName = (barber['salonName'] as String?) ?? '';
    final status = (barber['status'] as String?) ?? 'pending';
    final createdAt = barber['createdAt'] as String?;

    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider, width: 1.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 13, color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            salonName.isNotEmpty ? salonName : '—',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            // Details row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                        icon: Icons.phone_outlined, text: phone),
                  ),
                  if (createdAt != null)
                    Expanded(
                      child: _DetailItem(
                        icon: Icons.schedule_rounded,
                        text: _formatDate(createdAt),
                      ),
                    ),
                ],
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(
                            color: Colors.red.shade200, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reddet',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Onayla',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Onaylı', AppTheme.success),
      'rejected' => ('Reddedildi', Colors.red.shade400),
      _ => ('Bekliyor', AppTheme.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
