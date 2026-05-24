import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';
import '../services/barber_service.dart';
import '../services/saved_barbers_service.dart';
import '../utils/app_theme.dart';
import 'booking_screen.dart';

class BarberProfileScreen extends StatefulWidget {
  final Barber barber;
  const BarberProfileScreen({super.key, required this.barber});

  @override
  State<BarberProfileScreen> createState() => _BarberProfileScreenState();
}

class _BarberProfileScreenState extends State<BarberProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorited = false;
  final Set<String> _selectedServices = {};

  late Barber _barber;
  List<ReviewModel> _reviews = [];
  bool _isLoadingDetail = false;
  bool _detailError = false;

  Barber get barber => _barber;

  @override
  void initState() {
    super.initState();
    _barber = widget.barber;
    _tabController = TabController(length: 4, vsync: this);
    _loadDetail();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await SavedBarbersService.isSaved(_barber.id);
    if (mounted) setState(() => _isFavorited = saved);
  }

  Future<void> _toggleSave() async {
    final nowSaved = await SavedBarbersService.toggle(_barber);
    if (!mounted) return;
    setState(() => _isFavorited = nowSaved);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(nowSaved ? '❤️ Kaydedildi' : '🤍 Kaydedilenlerden kaldırıldı'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _share() {
    final text =
        '${barber.name}\n📍 ${barber.address}, ${barber.city}\n⭐ ${barber.rating.toStringAsFixed(1)} (${barber.reviewCount} yorum)';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('📋 Bilgiler panoya kopyalandı'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoadingDetail = true; _detailError = false; });
    try {
      final detail = await BarberService.getBarberDetail(_barber.id);
      final reviews = await BarberService.getBarberReviews(_barber.id);
      if (mounted) {
        setState(() {
          _barber = detail;
          _reviews = reviews;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingDetail = false; _detailError = true; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              _buildSliverAppBar(),
              _buildSliverTabBar(),
            ],
            body: _isLoadingDetail && barber.services.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2.5))
                : _detailError && barber.services.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 48, color: AppTheme.textTertiary),
                          const SizedBox(height: 16),
                          const Text(
                            'Bilgiler yüklenemedi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bağlantını kontrol edip tekrar dene',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Tekrar Dene'),
                            onPressed: _loadDetail,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ServicesTab(
                        services: barber.services,
                        selectedServices: _selectedServices,
                        onToggleService: (id) {
                          setState(() {
                            _selectedServices.contains(id)
                                ? _selectedServices.remove(id)
                                : _selectedServices.add(id);
                          });
                        },
                      ),
                      _PortfolioTab(images: barber.portfolioImages),
                      _AboutTab(barber: barber),
                      _ReviewsTab(
                        barber: barber,
                        reviews: _reviews,
                        onReviewSubmitted: _loadDetail,
                      ),
                    ],
                  ),
          ),
          // Floating bottom booking bar
          if (_selectedServices.isNotEmpty)
            _buildBookingBar(),
        ],
      ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: context.bg,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _CircleIconButton(
            icon: _isFavorited
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: _isFavorited ? Colors.redAccent : AppTheme.textPrimary,
            onTap: _toggleSave,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          child: _CircleIconButton(
            icon: Icons.share_rounded,
            onTap: _share,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          children: [
            // Cover image
            Image.network(
              barber.coverImage,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.divider,
                child: const Center(
                  child: Icon(Icons.content_cut_rounded,
                      size: 50, color: AppTheme.textTertiary),
                ),
              ),
            ),
            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      context.bg,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Profile info at bottom of cover
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        barber.avatarImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.divider,
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.textTertiary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 13,
                                color: AppTheme.textSecondary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${barber.address}, ${barber.city}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppTheme.starColor),
                            const SizedBox(width: 3),
                            Text(
                              barber.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${barber.reviewCount} yorum',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hizmetler'),
            Tab(text: 'Portfolyo'),
            Tab(text: 'Hakkında'),
            Tab(text: 'Yorumlar'),
          ],
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textTertiary,
          labelStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500),
          indicator: const UnderlineTabIndicator(
            borderSide:
                BorderSide(width: 2.5, color: AppTheme.accent),
            insets: EdgeInsets.symmetric(horizontal: 16),
          ),
          dividerColor: AppTheme.divider,
        ),
      ),
    );
  }

  // ── Booking Bar ────────────────────────────────────────────────────────────
  Widget _buildBookingBar() {
    final total = barber.services
        .where((s) => _selectedServices.contains(s.id))
        .fold<double>(0, (sum, s) => sum + s.price);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: context.surf,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedServices.length} hizmet seçildi',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  '₺${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _showBookingConfirmation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Randevu Al',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          barber: barber,
          selectedServiceIds: _selectedServices,
        ),
      ),
    );
  }
}

// ── Tab 1: Services ───────────────────────────────────────────────────────────
class _ServicesTab extends StatelessWidget {
  final List<ServiceModel> services;
  final Set<String> selectedServices;
  final void Function(String) onToggleService;

  const _ServicesTab({
    required this.services,
    required this.selectedServices,
    required this.onToggleService,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final service = services[i];
        final isSelected = selectedServices.contains(service.id);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.04)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.divider,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? [] : AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.08)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(service.icon,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name, style: AppTheme.titleMedium),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(service.duration,
                              style: AppTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₺${service.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => onToggleService(service.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isSelected ? 'Seçildi ✓' : 'Seç',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 2: Portfolio ──────────────────────────────────────────────────────────
class _PortfolioTab extends StatelessWidget {
  final List<String> images;
  const _PortfolioTab({required this.images});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: images.length,
      itemBuilder: (ctx, i) {
        return GestureDetector(
          onTap: () => _showImagePreview(context, i),
          child: Hero(
            tag: 'portfolio_$i',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                images[i],
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppTheme.divider,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.divider,
                  child: const Center(
                    child: Icon(Icons.image_rounded,
                        color: AppTheme.textTertiary, size: 32),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImagePreview(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            _ImagePreviewScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

// ── Tab 3: About ──────────────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  final Barber barber;
  const _AboutTab({required this.barber});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _section('Hakkında',
            child: Text(barber.about.isNotEmpty ? barber.about : '—',
                style: AppTheme.bodyMedium)),
        const SizedBox(height: 20),
        _section('Çalışma Saatleri',
            child: Column(
              children: barber.workingHours.entries
                  .map((e) => _hoursRow(e.key, e.value))
                  .toList(),
            )),
        const SizedBox(height: 20),
        _section('Konum',
            child: Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${barber.address}, ${barber.city}',
                    style: AppTheme.bodyMedium),
              ),
            ])),
        if (barber.phone != null && barber.phone!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _section('İletişim',
              child: GestureDetector(
                onTap: () => launchUrl(Uri(scheme: 'tel', path: barber.phone)),
                child: Row(children: [
                  const Icon(Icons.phone_rounded,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    barber.phone!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.accent,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.accent,
                    ),
                  ),
                ]),
              )),
        ],
      ],
    );
  }

  Widget _section(String title, {required Widget child}) => Builder(
    builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surf,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.shadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTheme.titleMedium),
          const SizedBox(height: 14),
          Divider(color: context.div, height: 1),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );

  Widget _hoursRow(String day, String hours) {
    final closed = hours == 'Closed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary)),
          Text(hours,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: closed ? Colors.redAccent : AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ── Tab 4: Reviews ────────────────────────────────────────────────────────────
class _ReviewsTab extends StatefulWidget {
  final Barber barber;
  final List<ReviewModel> reviews;
  final VoidCallback onReviewSubmitted;

  const _ReviewsTab({
    required this.barber,
    required this.reviews,
    required this.onReviewSubmitted,
  });

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  String? _reviewableAppointmentId;
  bool _checkingReview = true;

  @override
  void initState() {
    super.initState();
    _checkCanReview();
  }

  Future<void> _checkCanReview() async {
    try {
      final id = await BarberService.getReviewableAppointmentId(widget.barber.id);
      if (mounted) setState(() { _reviewableAppointmentId = id; _checkingReview = false; });
    } catch (_) {
      if (mounted) setState(() => _checkingReview = false);
    }
  }

  void _openSheet() {
    if (_reviewableAppointmentId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        appointmentId: _reviewableAppointmentId!,
        onSubmitted: () {
          widget.onReviewSubmitted();
          setState(() => _reviewableAppointmentId = null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barber = widget.barber;
    final reviews = widget.reviews;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── Rating summary ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surf,
            borderRadius: BorderRadius.circular(20),
            boxShadow: context.shadow,
          ),
          child: Row(children: [
            Column(children: [
              Text(
                barber.rating > 0
                    ? barber.rating.toStringAsFixed(1)
                    : '—',
                style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                      i < barber.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: AppTheme.starColor)),
              ),
              const SizedBox(height: 4),
              Text('${barber.reviewCount} yorum',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: List.generate(5, (i) {
                  final star  = 5 - i;
                  final count = reviews.where((r) => r.rating == star).length;
                  final frac  = reviews.isEmpty ? 0.0 : count / reviews.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Text('$star',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 12, color: AppTheme.starColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 6,
                            backgroundColor: AppTheme.divider,
                            valueColor: const AlwaysStoppedAnimation(
                                AppTheme.starColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 18,
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textTertiary)),
                      ),
                    ]),
                  );
                }),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Yorum Yaz button ─────────────────────────────────────────────
        if (_checkingReview)
          const SizedBox(height: 50,
              child: Center(child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primary)))
        else if (_reviewableAppointmentId != null)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('Yorum Yaz'),
            onPressed: _openSheet,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Review cards ─────────────────────────────────────────────────
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.surf,
              borderRadius: BorderRadius.circular(20),
              boxShadow: context.shadow,
            ),
            child: const Center(
              child: Column(children: [
                Text('⭐', style: TextStyle(fontSize: 36)),
                SizedBox(height: 12),
                Text('Henüz yorum yok',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textSecondary)),
                SizedBox(height: 4),
                Text('İlk yorumu sen yap!',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textTertiary)),
              ]),
            ),
          )
        else
          ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

// ── Review Bottom Sheet ───────────────────────────────────────────────────────
class _ReviewSheet extends StatefulWidget {
  final String appointmentId;
  final VoidCallback onSubmitted;
  const _ReviewSheet({required this.appointmentId, required this.onSubmitted});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int    _rating    = 0;
  final  _ctrl      = TextEditingController();
  bool   _submitting = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    try {
      await BarberService.submitReview(
        widget.appointmentId,
        rating:  _rating,
        comment: _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
      );
      if (!mounted) return;
      // Capture messenger before pop — context becomes stale after Navigator.pop
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
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: context.surf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Yorum Yap',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Deneyimini diğerleriyle paylaş',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),

          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 42,
                    color: star <= _rating
                        ? AppTheme.starColor
                        : AppTheme.textTertiary,
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 8),
            Text(
              ['', 'Berbat 😞', 'Kötü 😐', 'İyi 👍', 'Harika 😊', 'Mükemmel 🤩'][_rating],
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent),
            ),
          ],
          const SizedBox(height: 20),

          // Comment
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Yorumunuzu yazın... (isteğe bağlı)',
                hintStyle: TextStyle(
                    color: AppTheme.textTertiary, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                counterStyle: TextStyle(
                    color: AppTheme.textTertiary, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _rating > 0 && !_submitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rating > 0
                    ? AppTheme.primary
                    : AppTheme.divider,
                foregroundColor: _rating > 0
                    ? Colors.white
                    : AppTheme.textTertiary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Yorum Gönder',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surf,
        borderRadius: BorderRadius.circular(18),
        boxShadow: context.shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              review.authorAvatar,
              width: 40, height: 40, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40, height: 40,
                color: AppTheme.divider,
                child: const Icon(Icons.person_rounded,
                    size: 22, color: AppTheme.textTertiary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(review.authorName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                        i < review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 13, color: AppTheme.starColor)),
                  const SizedBox(width: 6),
                  Text(review.date, style: AppTheme.labelSmall),
                ],
              ),
            ]),
          ),
        ]),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(review.comment, style: AppTheme.bodyMedium),
        ],
      ]),
    );
  }
}

// ── Image Preview Screen ──────────────────────────────────────────────────────
class _ImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _ImagePreviewScreen(
      {required this.images, required this.initialIndex});

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) {
              return InteractiveViewer(
                child: Center(
                  child: Hero(
                    tag: 'portfolio_$i',
                    child: Image.network(widget.images[i], fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          // Page indicator
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _currentIndex ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _currentIndex
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.surf.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.bg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}