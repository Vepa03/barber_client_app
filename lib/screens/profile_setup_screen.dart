import 'package:flutter/material.dart';
import '../services/barber_service.dart';
import '../services/api_client.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool editMode;
  const ProfileSetupScreen({super.key, this.editMode = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();

  List<Map<String, String>> _cities = [];
  String? _selectedCityId;
  bool _isLoading = false;
  bool _citiesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final cities = await BarberService.getCities();

      // Edit modunda mevcut profil bilgilerini doldur
      if (widget.editMode) {
        final profile = await ApiClient.get('/auth/me') as Map<String, dynamic>;
        final fullName = (profile['fullName'] as String?) ?? '';
        final parts = fullName.trim().split(' ');
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : '';

        final city = profile['city'] as Map<String, dynamic>?;
        final currentCityId = city?['id'] as String?;

        if (mounted) {
          setState(() {
            _cities = cities;
            _selectedCityId = currentCityId ??
                (cities.isNotEmpty ? cities[0]['id'] : null);
            _citiesLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cities = cities;
            _selectedCityId = cities.isNotEmpty ? cities[0]['id'] : null;
            _citiesLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _citiesLoading = false);
    }
  }

  bool get _canSubmit =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _selectedCityId != null &&
      !_isLoading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    try {
      await ApiClient.patch('/auth/me', {
        'fullName': fullName,
        'cityId': _selectedCityId,
      });
      if (!mounted) return;

      if (widget.editMode) {
        Navigator.pop(context);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: widget.editMode
          ? AppBar(
              backgroundColor: AppTheme.background,
              title: const Text('Profili Düzenle'),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.editMode) ...[
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 48),
                  Text('Profilini\ntamamla.', style: AppTheme.displayLarge),
                  const SizedBox(height: 10),
                  const Text(
                    'Sana daha iyi hizmet verebilmemiz\niçin birkaç bilgiye ihtiyacımız var.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ] else
                  const SizedBox(height: 16),
                const SizedBox(height: 40),
                _buildField(
                  label: 'Ad',
                  controller: _firstNameController,
                  hint: 'Adınız',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Soyad',
                  controller: _lastNameController,
                  hint: 'Soyadınız',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildCityPicker(),
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text('💈', style: TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BarberBook',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Premium Grooming, Booked.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider, width: 1.5),
            boxShadow: AppTheme.cardShadow,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nerede yaşıyorsun?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider, width: 1.5),
            boxShadow: AppTheme.cardShadow,
          ),
          child: _citiesLoading
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCityId,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    borderRadius: BorderRadius.circular(16),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    items: _cities
                        .map((c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['name']!),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCityId = val),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _canSubmit ? AppTheme.buttonShadow : [],
        ),
        child: ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _canSubmit ? AppTheme.primary : AppTheme.divider,
            foregroundColor:
                _canSubmit ? Colors.white : AppTheme.textTertiary,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  widget.editMode ? 'Kaydet' : 'Devam Et',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
