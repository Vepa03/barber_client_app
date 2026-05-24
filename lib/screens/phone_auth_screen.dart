import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'category_screen.dart';
import 'profile_setup_screen.dart';

enum _Step { phone, otp }
enum _Mode { login, register }

class PhoneAuthScreen extends StatefulWidget {
  /// null geçilirse ekran mode seçim adımından başlar.
  /// true → kayıt, false → giriş
  final bool? startAsRegister;

  const PhoneAuthScreen({super.key, this.startAsRegister});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with SingleTickerProviderStateMixin {
  late _Step _step;
  late _Mode _mode;

  final _phoneCtrl = TextEditingController();
  final _otpCtrls  = List.generate(4, (_) => TextEditingController());
  final _otpNodes  = List.generate(4, (_) => FocusNode());

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _step = _Step.phone;
    _mode = (widget.startAsRegister ?? false) ? _Mode.register : _Mode.login;

    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpNodes) f.dispose();
    super.dispose();
  }

  // +993 XX XXXXXX  —  Türkmenistan
  String get _fullPhone => '+993${_phoneCtrl.text.replaceAll(RegExp(r'\s'), '')}';

  void _goStep(_Step s) {
    _anim.reset();
    setState(() => _step = s);
    _anim.forward();
  }

  void _snack(String msg, {bool red = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: red ? Colors.redAccent : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _sendOtp() async {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 8) return;
    setState(() => _loading = true);
    try {
      final exists = await AuthService.checkPhone(_fullPhone);

      if (_mode == _Mode.register && exists) {
        _snack('Bu numara zaten kayıtlı. Lütfen giriş yapın.', red: true);
        setState(() => _loading = false);
        return;
      }
      if (_mode == _Mode.login && !exists) {
        _snack('Bu numara kayıtlı değil. Lütfen kayıt olun.', red: true);
        setState(() => _loading = false);
        return;
      }

      await AuthService.requestOtp(_fullPhone);
      _snack('OTP kodu gönderildi (Dev: 1234)');
      setState(() => _loading = false);
      _goStep(_Step.otp);
      Future.delayed(const Duration(milliseconds: 150),
          () => _otpNodes[0].requestFocus());
    } catch (e) {
      setState(() => _loading = false);
      _snack(e.toString(), red: true);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 4) return;
    setState(() => _loading = true);
    try {
      final isNew = await AuthService.verifyOtp(_fullPhone, otp);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isNew ? const ProfileSetupScreen() : const CategoryScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() => _loading = false);
      _snack(e.toString(), red: true);
    }
  }

  void _onOtpChanged(String val, int i) {
    if (val.length == 1 && i < 3) { _otpNodes[i + 1].requestFocus(); }
    if (val.isEmpty && i > 0)     { _otpNodes[i - 1].requestFocus(); }
    final full = _otpCtrls.map((c) => c.text).join();
    if (full.length == 4) { _verifyOtp(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: switch (_step) {
              _Step.phone => _buildPhoneStep(),
              _Step.otp   => _buildOtpStep(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\s'), '');
    final canProceed = digits.length >= 8;
    final title    = _mode == _Mode.register ? 'Kayıt Ol' : 'Giriş Yap';
    final subtitle = _mode == _Mode.register
        ? 'Telefon numaranı gir, sana bir doğrulama kodu gönderelim.'
        : 'Kayıtlı telefon numaranı gir.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 32),
          Text(title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 36),
          const Text('Telefon Numarası',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider, width: 1.5),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                  decoration: const BoxDecoration(
                    border: Border(
                        right: BorderSide(
                            color: AppTheme.divider, width: 1.5)),
                  ),
                  child: const Text('🇹🇲 +993',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'XX XXXXXX',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => canProceed ? _sendOtp() : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _actionBtn(
            label: 'Kod Gönder',
            enabled: canProceed,
            onTap: _sendOtp,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    final allFilled = _otpCtrls.every((c) => c.text.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              for (final c in _otpCtrls) c.clear();
              _goStep(_Step.phone);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Kodu Gir',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5),
              children: [
                const TextSpan(text: '+993 '),
                TextSpan(
                  text: _phoneCtrl.text,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                const TextSpan(
                    text: ' numarasına gönderilen 4 haneli kodu gir.'),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, _buildOtpBox),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text("Kod gelmedi mi? ",
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              GestureDetector(
                onTap: _sendOtp,
                child: const Text('Tekrar Gönder',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _actionBtn(
            label: 'Doğrula',
            enabled: allFilled,
            onTap: _verifyOtp,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int i) {
    return SizedBox(
      width: 68,
      height: 68,
      child: TextField(
        controller: _otpCtrls[i],
        focusNode: _otpNodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppTheme.divider, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppTheme.divider, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppTheme.primary, width: 2.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) => _onOtpChanged(val, i),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled ? AppTheme.buttonShadow : [],
        ),
        child: ElevatedButton(
          onPressed: enabled && !_loading ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? AppTheme.primary : AppTheme.divider,
            foregroundColor: enabled ? Colors.white : AppTheme.textTertiary,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
