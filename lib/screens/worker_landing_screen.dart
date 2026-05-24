import 'package:flutter/material.dart';
import 'phone_auth_screen.dart';

class WorkerLandingScreen extends StatelessWidget {
  const WorkerLandingScreen({super.key});

  static const _bg     = Color(0xFFF4F4F4);
  static const _black  = Color(0xFF1A1A1A);
  static const _grey   = Color(0xFF888888);
  static const _greyLight = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _Logo(),
              const Spacer(),
              _Badge(),
              const SizedBox(height: 22),
              const Text(
                'Run your\nchair, your\nway.',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: _black,
                  height: 1.08,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Bookings, reviews, payouts and your week — all in one place. Built for barbers, stylists, therapists and detailers.',
                style: TextStyle(
                  fontSize: 15,
                  color: _grey,
                  height: 1.65,
                ),
              ),
              const Spacer(),
              _PillButton(
                label: 'Hesap Oluştur',
                filled: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PhoneAuthScreen(startAsRegister: true),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhoneAuthScreen(startAsRegister: false),
                    ),
                  ),
                  child: const Text(
                    'Zaten hesabım var',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Devam ederek Kullanım Şartları ve Gizlilik Politikasını kabul etmiş olursunuz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _greyLight,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.content_cut_rounded, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Dellekci',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Türkmenistan',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4060CC),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1A1A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          border: filled ? null : Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : const Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
