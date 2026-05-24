import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_client.dart' show ApiClient, ApiException;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/app_theme.dart';
import 'worker_landing_screen.dart';
import 'profile_setup_screen.dart';
import 'notifications_screen.dart';
import 'saved_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _uploadingPhoto = false;
  int _bookingCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await ApiClient.get('/auth/me') as Map<String, dynamic>;
      if (mounted) setState(() { _profile = data; _isLoading = false; });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token süresi dolmuş — çıkış yap ve login ekranına yönlendir
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WorkerLandingScreen()),
          (_) => false,
        );
        return;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.';
        });
      }
      return;
    }
    // Booking count is best-effort — don't let it block profile display
    try {
      final appts = await ApiClient.get('/appointments');
      int count = 0;
      if (appts is Map && appts['total'] != null) {
        count = (appts['total'] as num).toInt();
      } else if (appts is List) {
        count = appts.length;
      }
      if (mounted) setState(() => _bookingCount = count);
    } catch (_) {}
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await _showSourceDialog();
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ApiClient.uploadFile(File(picked.path));
      await ApiClient.patch('/auth/me', {'avatarUrl': url});
      if (mounted) {
        setState(() {
          _profile = {...?_profile, 'avatarUrl': url};
          _uploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Profil fotoğrafı güncellendi'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.surf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: ctx.div,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Fotoğraf Seç',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ctx.tp)),
            const SizedBox(height: 16),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Galeriden Seç',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            _SourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera ile Çek',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WorkerLandingScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hesabı Sil',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
        content: const Text(
          'Hesabınızı silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, Sil',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiClient.delete('/auth/me');
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WorkerLandingScreen()),
        (_) => false,
      );
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature yakında kullanıma açılacak'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
            : _profile == null
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: context.ts),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Profil yüklenemedi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: context.ts, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final p = _profile!;
    final fullName = (p['fullName'] as String?) ?? '';
    final phone = (p['phone'] as String?) ?? '';
    final avatarUrl = (p['avatarUrl'] as String?) ?? '';
    final city = p['city'] as Map<String, dynamic>?;
    final createdAt = p['createdAt'] as String?;

    final initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : phone.isNotEmpty ? phone[phone.length - 1] : '?';

    final memberSince = _formatMemberSince(createdAt);
    final cityName = city != null ? (city['name'] as String? ?? '') : '';
    final phoneDisplay = phone.isNotEmpty ? _maskPhone(phone) : '';
    final personalSubtitle = [
      if (fullName.isNotEmpty) fullName.split(' ').first,
      if (phoneDisplay.isNotEmpty) phoneDisplay,
    ].join(' · ');

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page title ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: context.tp,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // ── User card ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surf,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.shadow,
                ),
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            child: ClipOval(
                              child: avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, e, s) => _initialsAvatar(initials),
                                    )
                                  : _initialsAvatar(initials),
                            ),
                          ),
                          if (_uploadingPhoto)
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          if (!_uploadingPhoto)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.surface, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isNotEmpty ? fullName : 'İsimsiz Kullanıcı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.tp,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (memberSince.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Member since $memberSince',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.ts,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _StatChip(value: '$_bookingCount', label: 'bookings'),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Edit button
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileSetupScreen(editMode: true)),
                        );
                        _loadProfile();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit_outlined,
                            size: 18, color: context.ts),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── ACCOUNT section ─────────────────────────────────────────────
            _SectionHeader(label: 'ACCOUNT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surf,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.shadow,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal information',
                      subtitle: personalSubtitle,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileSetupScreen(editMode: true)),
                        );
                        _loadProfile();
                      },
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'On for bookings & deals',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── PREFERENCES section ─────────────────────────────────────────
            _SectionHeader(label: 'PREFERENCES'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surf,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.shadow,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: cityName.isNotEmpty ? 'Türkmen · $cityName' : 'Türkmen',
                      onTap: () => _showComingSoon('Dil ayarları'),
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: context.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      title: context.isDark ? 'Light Mode' : 'Dark Mode',
                      showChevron: false,
                      onTap: () => ThemeService.toggle().then((_) => setState(() {})),
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.favorite_border_rounded,
                      title: 'Saved places',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── SUPPORT section ─────────────────────────────────────────────
            _SectionHeader(label: 'SUPPORT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surf,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.shadow,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & FAQ',
                      onTap: () => _showComingSoon('Yardım'),
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Log out',
                      titleColor: Colors.red.shade600,
                      iconColor: Colors.red.shade400,
                      showChevron: false,
                      onTap: _logout,
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete account',
                      titleColor: Colors.red.shade800,
                      iconColor: Colors.red.shade300,
                      showChevron: false,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatMemberSince(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, phone.length - 6)}XX XX XX';
  }

  Widget _initialsAvatar(String initials) => Container(
        color: const Color(0xFFE8D5B0),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.accent,
            letterSpacing: 1,
          ),
        ),
      );
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.tt,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Menu Item ─────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showChevron;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
    this.iconColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? context.ts),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? context.tp,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.ts,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: context.tt),
          ],
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.div,
      indent: 72,
      endIndent: 0,
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.tp,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: context.ts,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Source Tile ───────────────────────────────────────────────────────────────
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.div),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: context.pri),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.tp)),
        ]),
      ),
    );
  }
}
