import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF4F4F4);
const _kBlack = Color(0xFF1A1A1A);
const _kGrey = Color(0xFF888888);
const _kGreyLight = Color(0xFFAAAAAA);
const _kBorder = Color(0xFFE8E8E8);
const _kBlue = Color(0xFF3875F6);
const _kBlueBg = Color(0xFFEBF2FE);

// ── Models ────────────────────────────────────────────────────────────────────
class _Service {
  String name;
  String price;
  String duration;
  _Service({required this.name, required this.price, required this.duration});
}

class _DaySchedule {
  final String day;
  bool enabled;
  TimeOfDay start;
  TimeOfDay end;
  _DaySchedule({
    required this.day,
    required this.enabled,
    required this.start,
    required this.end,
  });
}

// ── Main Widget ───────────────────────────────────────────────────────────────
class WorkerOnboardingScreen extends StatefulWidget {
  final String email;
  final String phone;

  const WorkerOnboardingScreen({
    super.key,
    required this.email,
    required this.phone,
  });

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  static const _totalSteps = 9;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Step 1 — Name
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  // Step 2 — Photos
  File? _coverPhoto;
  File? _profilePhoto;

  // Step 3 — City
  final _citySearchCtrl = TextEditingController();
  String? _selectedCity;
  final List<String> _allCities = [
    'Brooklyn, NY', 'Manhattan, NY', 'Queens, NY',
    'Los Angeles, CA', 'Chicago, IL', 'Austin, TX',
    'Miami, FL', 'Seattle, WA', 'Boston, MA', 'Denver, CO',
  ];

  // Step 4 — Work type
  String? _selectedWorkType;
  final _workTypes = [
    ('Barber', 'Cuts, shaves, beard work', Icons.content_cut_rounded),
    ('Salon', 'Hair, color, styling', Icons.auto_awesome_rounded),
    ('Massage', 'Therapeutic & relaxation', Icons.self_improvement_rounded),
    ('Car wash', 'Detail & quick wash', Icons.directions_car_rounded),
  ];

  // Step 5 — Shop name
  final _shopNameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();

  // Step 6 — Portfolio
  final List<File?> _portfolio = List.filled(6, null);

  // Step 7 — Bio
  final _yearsCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  // Step 8 — Services
  final List<_Service> _services = [
    _Service(name: 'Classic cut', price: '35', duration: '30'),
    _Service(name: 'Skin fade', price: '45', duration: '45'),
    _Service(name: 'Beard line-up', price: '25', duration: '20'),
  ];

  // Step 9 — Schedule
  final List<_DaySchedule> _schedule = [
    _DaySchedule(day: 'Mon', enabled: true, start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Tue', enabled: true, start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Wed', enabled: true, start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Thu', enabled: true, start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 18, minute: 0)),
    _DaySchedule(day: 'Fri', enabled: true, start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 20, minute: 0)),
    _DaySchedule(day: 'Sat', enabled: true, start: const TimeOfDay(hour: 10, minute: 0), end: const TimeOfDay(hour: 17, minute: 0)),
    _DaySchedule(day: 'Sun', enabled: false, start: const TimeOfDay(hour: 10, minute: 0), end: const TimeOfDay(hour: 16, minute: 0)),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _citySearchCtrl.dispose();
    _shopNameCtrl.dispose();
    _taglineCtrl.dispose();
    _yearsCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _goNext() async {
    if (_step < _totalSteps - 1) {
      await _fadeCtrl.reverse();
      setState(() => _step++);
      _fadeCtrl.forward();
    }
  }

  void _goBack() async {
    if (_step > 0) {
      await _fadeCtrl.reverse();
      setState(() => _step--);
      _fadeCtrl.forward();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage({bool cover = false, int? portfolioIndex}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() {
      if (cover) {
        _coverPhoto = File(picked.path);
      } else if (portfolioIndex != null) {
        _portfolio[portfolioIndex] = File(picked.path);
      } else {
        _profilePhoto = File(picked.path);
      }
    });
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _firstNameCtrl.text.trim().isNotEmpty && _lastNameCtrl.text.trim().isNotEmpty;
      case 1:
        return true;
      case 2:
        return _selectedCity != null;
      case 3:
        return _selectedWorkType != null;
      case 4:
        return _shopNameCtrl.text.trim().isNotEmpty;
      case 5:
        return true;
      case 6:
        return true;
      case 7:
        return _services.isNotEmpty;
      case 8:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: _buildStep(),
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.chevron_left, color: _kBlack, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_step + 1) / _totalSteps,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${_step + 1}/$_totalSteps',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ── Steps router ────────────────────────────────────────────────────────────
  Widget _buildStep() {
    return switch (_step) {
      0 => _buildNameStep(),
      1 => _buildPhotosStep(),
      2 => _buildCityStep(),
      3 => _buildWorkTypeStep(),
      4 => _buildShopNameStep(),
      5 => _buildPortfolioStep(),
      6 => _buildBioStep(),
      7 => _buildServicesStep(),
      8 => _buildScheduleStep(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Bottom button ────────────────────────────────────────────────────────────
  Widget _buildBottomButton() {
    final isLast = _step == _totalSteps - 1;
    final isSkippable = _step == 5;
    final label = isLast
        ? 'Open dashboard'
        : isSkippable && _portfolio.every((f) => f == null)
            ? 'Skip for now'
            : 'Continue';

    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: GestureDetector(
        onTap: _canProceed ? _goNext : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _canProceed ? _kBlack : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _canProceed ? Colors.white : const Color(0xFFAAAAAA),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.north_east_rounded,
                size: 18,
                color: _canProceed ? Colors.white : const Color(0xFFAAAAAA),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 1 — Name
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What's your name?", style: _kHeadline),
          const SizedBox(height: 8),
          const Text(
            'This is how customers will see you in the app.',
            style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
          ),
          const SizedBox(height: 36),
          _label('FIRST NAME'),
          const SizedBox(height: 8),
          _textField(controller: _firstNameCtrl, hint: 'Alex'),
          const SizedBox(height: 16),
          _label('LAST NAME'),
          const SizedBox(height: 8),
          _textField(controller: _lastNameCtrl, hint: 'Rivera'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 2 — Photos
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add your photos', style: _kHeadline),
          const SizedBox(height: 8),
          const Text(
            'A profile photo and a cover image help customers recognize you and your space.',
            style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
          ),
          const SizedBox(height: 28),
          _label('COVER PHOTO'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pickImage(cover: true),
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder, width: 1.5),
              ),
              child: _coverPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_coverPhoto!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 28, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 8),
                        Text('Tap to add cover photo',
                            style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Wide image, 16:9 works best',
              style: TextStyle(fontSize: 12, color: _kGreyLight)),
          const SizedBox(height: 24),
          _label('PROFILE PHOTO'),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _pickImage(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder),
                  ),
                  child: _profilePhoto != null
                      ? ClipOval(
                          child: Image.file(_profilePhoto!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.person_outline_rounded,
                          size: 30, color: Color(0xFFAAAAAA)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a profile photo',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kBlack)),
                    SizedBox(height: 4),
                    Text('Square image. Customers see this on your profile and in chats.',
                        style: TextStyle(fontSize: 12, color: _kGrey, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _photoSourceButton(
                icon: Icons.camera_alt_outlined,
                label: 'From camera',
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (picked != null && mounted) setState(() => _profilePhoto = File(picked.path));
                },
              ),
              const SizedBox(width: 12),
              _photoSourceButton(
                icon: Icons.photo_library_outlined,
                label: 'From library',
                onTap: () => _pickImage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoSourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _kBlack),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kBlack)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 3 — City
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildCityStep() {
    final query = _citySearchCtrl.text.toLowerCase();
    final filtered = _allCities
        .where((c) => c.toLowerCase().contains(query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Which city do\nyou work in?', style: _kHeadline),
              const SizedBox(height: 8),
              const Text(
                "We'll show your services to nearby customers.",
                style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
              ),
              const SizedBox(height: 24),
              _label('SEARCH'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _citySearchCtrl,
                        style: const TextStyle(fontSize: 15, color: _kBlack),
                        decoration: const InputDecoration(
                          hintText: 'Type a city',
                          hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 15),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final city = filtered[i];
              final selected = _selectedCity == city;
              return GestureDetector(
                onTap: () => setState(() => _selectedCity = city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: selected ? _kBlueBg : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? _kBlue.withOpacity(0.4) : _kBorder,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18,
                          color: selected ? _kBlue : const Color(0xFFAAAAAA)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(city,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected ? _kBlue : _kBlack,
                            )),
                      ),
                      if (selected)
                        const Icon(Icons.check_rounded, size: 18, color: _kBlue),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 4 — Work type
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildWorkTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What kind of\nwork do you do?', style: _kHeadline),
          const SizedBox(height: 8),
          const Text(
            'Pick the category that fits best. You can offer multiple services later.',
            style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: _workTypes.length,
            itemBuilder: (_, i) {
              final (name, desc, icon) = _workTypes[i];
              final selected = _selectedWorkType == name;
              return GestureDetector(
                onTap: () => setState(() => _selectedWorkType = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selected ? _kBlueBg : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? _kBlue.withOpacity(0.4) : _kBorder,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected ? _kBlue : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: selected ? Colors.white : const Color(0xFF888888)),
                      ),
                      const Spacer(),
                      Text(name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected ? _kBlue : _kBlack,
                          )),
                      const SizedBox(height: 4),
                      Text(desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? _kBlue.withOpacity(0.7) : _kGrey,
                            height: 1.3,
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 5 — Shop name
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildShopNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Name your shop', style: _kHeadline),
          const SizedBox(height: 8),
          const Text(
            "If you work at a salon or shop, use its name. If you're solo, your own works great.",
            style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
          ),
          const SizedBox(height: 32),
          _label('SHOP / BUSINESS NAME'),
          const SizedBox(height: 8),
          _textField(controller: _shopNameCtrl, hint: 'North Side Cuts'),
          const SizedBox(height: 16),
          _label('TAGLINE (OPTIONAL)'),
          const SizedBox(height: 8),
          _textField(controller: _taglineCtrl, hint: 'Sharp fades. Honest prices.'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "You can add services, prices and photos from your dashboard once you're in.",
                    style: TextStyle(fontSize: 13, color: _kBlue, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 6 — Portfolio
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildPortfolioStep() {
    final addedCount = _portfolio.where((f) => f != null).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Show your work', style: _kHeadline),
          const SizedBox(height: 8),
          const Text(
            'Add a few photos so customers can see your style. You can add more later.',
            style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 6,
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () => _pickImage(portfolioIndex: i),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder, width: 1.5),
                  ),
                  child: _portfolio[i] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_portfolio[i]!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Icon(Icons.add, size: 22, color: Color(0xFFCCCCCC)),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _photoSourceButton(
                icon: Icons.camera_alt_outlined,
                label: 'From camera',
                onTap: () async {
                  final empty = _portfolio.indexWhere((f) => f == null);
                  if (empty == -1) return;
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (picked != null && mounted) setState(() => _portfolio[empty] = File(picked.path));
                },
              ),
              const SizedBox(width: 12),
              _photoSourceButton(
                icon: Icons.photo_library_outlined,
                label: 'From library',
                onTap: () async {
                  final empty = _portfolio.indexWhere((f) => f == null);
                  if (empty == -1) return;
                  _pickImage(portfolioIndex: empty);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$addedCount of 6 added · square photos work best',
            style: const TextStyle(fontSize: 12, color: _kGreyLight),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 7 — Bio
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildBioStep() {
    final bioLen = _bioCtrl.text.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell customers\nabout you', style: _kHeadline),
          const SizedBox(height: 8),
          const Text(
            'A short intro builds trust. Mention your style, training, what you love about the craft.',
            style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
          ),
          const SizedBox(height: 32),
          _label('YEARS OF EXPERIENCE'),
          const SizedBox(height: 8),
          _textField(
            controller: _yearsCtrl,
            hint: 'e.g. 5',
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _label('ABOUT YOU'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 1.5),
            ),
            child: TextField(
              controller: _bioCtrl,
              maxLines: 5,
              maxLength: 240,
              style: const TextStyle(fontSize: 15, color: _kBlack, height: 1.5),
              decoration: InputDecoration(
                hintText: "Hey, I'm Alex. I specialize in skin fades and beard line-ups. Trained at the Brooklyn Cut Co-op...",
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, height: 1.5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Markdown isn\'t supported. Plain text only.',
                  style: TextStyle(fontSize: 11, color: _kGreyLight)),
              Text('$bioLen/240',
                  style: const TextStyle(fontSize: 11, color: _kGreyLight)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✦', style: TextStyle(fontSize: 14, color: _kBlue)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tip: profiles with a real photo and 3+ sentences of bio get 2.4× more bookings in the first month.',
                    style: TextStyle(fontSize: 13, color: _kBlue, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 8 — Services
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildServicesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What do you offer?', style: _kHeadline),
              const SizedBox(height: 8),
              const Text(
                'Set your services and prices. You can edit these any time from your profile.',
                style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            children: [
              ..._services.asMap().entries.map((entry) {
                final i = entry.key;
                final svc = entry.value;
                return _ServiceCard(
                  service: svc,
                  onRemove: () => setState(() => _services.removeAt(i)),
                  onChanged: () => setState(() {}),
                );
              }),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _services.add(_Service(name: '', price: '', duration: ''));
                  });
                },
                child: Row(
                  children: const [
                    Icon(Icons.add, size: 18, color: _kBlack),
                    SizedBox(width: 6),
                    Text('Add service',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kBlack,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 9 — Schedule
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('When do you work?', style: _kHeadline),
              SizedBox(height: 8),
              Text(
                'Set the hours customers can book you. You can block off specific days or hours later.',
                style: TextStyle(fontSize: 15, color: _kGrey, height: 1.5),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder, width: 1),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _schedule.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final day = _schedule[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Switch(
                        value: day.enabled,
                        onChanged: (v) => setState(() => day.enabled = v),
                        activeColor: _kBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 36,
                        child: Text(
                          day.day,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: day.enabled ? _kBlack : _kGreyLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (day.enabled) ...[
                        _timePill(day.start, () async {
                          final t = await showTimePicker(context: context, initialTime: day.start);
                          if (t != null) setState(() => day.start = t);
                        }),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('—', style: TextStyle(color: _kGreyLight)),
                        ),
                        _timePill(day.end, () async {
                          final t = await showTimePicker(context: context, initialTime: day.end);
                          if (t != null) setState(() => day.end = t);
                        }),
                      ] else
                        const Text('Closed',
                            style: TextStyle(fontSize: 14, color: _kGreyLight)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _timePill(TimeOfDay time, VoidCallback onTap) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$h:$m',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kBlack)),
            const SizedBox(width: 4),
            const Icon(Icons.access_time_rounded, size: 13, color: _kGreyLight),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kGrey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kBlack),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 15),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

}

// ── Service Card ──────────────────────────────────────────────────────────────
class _ServiceCard extends StatefulWidget {
  final _Service service;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ServiceCard({
    required this.service,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service.name);
    _priceCtrl = TextEditingController(text: widget.service.price);
    _durationCtrl = TextEditingController(text: widget.service.duration);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _kBlack),
                  decoration: const InputDecoration(
                    hintText: 'Service name',
                    hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    widget.service.name = v;
                    widget.onChanged();
                  },
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFFBBBBBB)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('\$',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _kGrey)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kBlack),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          widget.service.price = v;
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kBlack),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          widget.service.duration = v;
                          widget.onChanged();
                        },
                      ),
                    ),
                    const Text(' min',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kGrey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared text style ─────────────────────────────────────────────────────────
const _kHeadline = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w800,
  color: _kBlack,
  height: 1.15,
  letterSpacing: -0.5,
);
