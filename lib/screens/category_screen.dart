import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class _Category {
  final String? type;
  final String emoji;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final Color textColor;
  final Color glowColor;

  const _Category({
    required this.type,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.textColor,
    required this.glowColor,
  });
}

const _kCategories = [
  _Category(
    type: 'barber',
    emoji: '💈',
    label: 'Berber',
    subtitle: 'Saç & Sakal',
    gradient: [Color(0xFF1A1A2E), Color(0xFF2D2D56)],
    textColor: Colors.white,
    glowColor: Color(0xFFE8A045),
  ),
  _Category(
    type: 'womens_salon',
    emoji: '💅',
    label: 'Kız Salonu',
    subtitle: 'Güzellik & Bakım',
    gradient: [Color(0xFFD63384), Color(0xFFFF6B9D)],
    textColor: Colors.white,
    glowColor: Color(0xFFFF6B9D),
  ),
  _Category(
    type: 'massage',
    emoji: '💆',
    label: 'Masaj',
    subtitle: 'Rahatlama & Terapi',
    gradient: [Color(0xFF0BA360), Color(0xFF3CBA92)],
    textColor: Colors.white,
    glowColor: Color(0xFF3CBA92),
  ),
  _Category(
    type: 'car_wash',
    emoji: '🚗',
    label: 'Araba Yıkama',
    subtitle: 'Temizlik & Bakım',
    gradient: [Color(0xFF4776E6), Color(0xFF8E54E9)],
    textColor: Colors.white,
    glowColor: Color(0xFF8E54E9),
  ),
];

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final List<AnimationController> _cardCtrls;
  String? _pressedType;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cardCtrls = List.generate(
      _kCategories.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 550),
      ),
    );

    _runEntrance();
  }

  Future<void> _runEntrance() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerCtrl.forward();
    for (var i = 0; i < _cardCtrls.length; i++) {
      await Future.delayed(const Duration(milliseconds: 110));
      _cardCtrls[i].forward();
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _cardCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCategoryTap(_Category cat) async {
    setState(() => _pressedType = cat.type);
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            HomeScreen(initialVenueType: cat.type),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Üst dekoratif arka plan
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -100,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Expanded(child: _buildGrid(size)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final fade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.40),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💈', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dellekci',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Bugün ne\narıyorsun?',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.15,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bir kategori seç',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(Size size) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.88,
      children: List.generate(_kCategories.length, (i) {
        final cat = _kCategories[i];
        final ctrl = _cardCtrls[i];
        final fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: _CategoryCard(
              category: cat,
              pressed: _pressedType == cat.type,
              onTap: () => _onCategoryTap(cat),
            ),
          ),
        );
      }),
    );
  }

}

class _CategoryCard extends StatefulWidget {
  final _Category category;
  final bool pressed;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.pressed,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isDown || widget.pressed ? 0.94 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isDown = true),
      onTapUp: (_) {
        setState(() => _isDown = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isDown = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.category.gradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.category.glowColor.withValues(alpha: 0.38),
                blurRadius: 22,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dekoratif daire
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -10,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // İçerik
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji container
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          widget.category.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.category.label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: widget.category.textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.category.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: widget.category.textColor.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Ok ikonu
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.category.textColor,
                        size: 14,
                      ),
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
}
