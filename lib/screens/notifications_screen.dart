import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enabled = true;
  int _minutes = 30;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      NotificationService.isEnabled(),
      NotificationService.getReminderMinutes(),
    ]);
    if (mounted) {
      setState(() {
        _enabled = results[0] as bool;
        _minutes = results[1] as int;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await NotificationService.setEnabled(value);
  }

  Future<void> _changeMinutes(int minutes) async {
    setState(() => _minutes = minutes);
    await NotificationService.setReminderMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: const Text('Bildirimler',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // ── Toggle card ─────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: context.surf,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: context.shadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _enabled
                                ? context.pri.withValues(alpha: 0.08)
                                : context.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            size: 20,
                            color: _enabled
                                ? AppTheme.primary
                                : AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Randevu hatırlatmaları',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _enabled
                                    ? NotificationService.labelFor(_minutes)
                                    : 'Kapalı',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enabled,
                          onChanged: _toggle,
                          activeColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Time picker (only when enabled) ─────────────────────────
                AnimatedOpacity(
                  opacity: _enabled ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          'NE KADAR ÖNCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textTertiary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: context.surf,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: context.shadow,
                        ),
                        child: Column(
                          children: NotificationService.minuteOptions
                              .map((opt) {
                            final selected = _minutes == opt;
                            final isLast = opt ==
                                NotificationService.minuteOptions.last;
                            return Column(
                              children: [
                                InkWell(
                                  onTap: _enabled
                                      ? () => _changeMinutes(opt)
                                      : null,
                                  borderRadius: BorderRadius.vertical(
                                    top: opt ==
                                            NotificationService
                                                .minuteOptions.first
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    bottom: isLast
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: selected
                                                  ? AppTheme.primary
                                                  : AppTheme.textTertiary,
                                              width: selected ? 6 : 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          NotificationService.labelFor(opt),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: selected
                                                ? AppTheme.textPrimary
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppTheme.divider,
                                    indent: 54,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Info text ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _enabled
                        ? 'Yaklaşan randevularınız için ${NotificationService.labelFor(_minutes)} otomatik hatırlatma alırsınız.'
                        : 'Bildirimler kapalı. Açmak için yukarıdaki düğmeyi kullanın.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
