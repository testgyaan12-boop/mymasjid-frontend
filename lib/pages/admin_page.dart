import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/biometric_service.dart';
import '../services/cms_service.dart';
import '../services/upload_service.dart';
import '../theme/colors.dart';
import '../providers/masjid_provider.dart';
import '../providers/theme_provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _authorized = false;
  final _passwordCtrl = TextEditingController();
  final _cmsService = CmsService();

  Map<String, dynamic> _cfg = {};

  // ---- Form controllers ----
  // Branding
  final _brandNameCtrl = TextEditingController();
  String _primH = '142', _primS = '76', _primL = '36';
  String _secH = '43', _secS = '76', _secL = '58';
  String? _brandLogoUrl;
  Uint8List? _brandLogoBytes;

  // Home
  final _homeStatusCtrl = TextEditingController();
  final _annTitleCtrl = TextEditingController();
  final _annDescCtrl = TextEditingController();

  // Sunnah
  final _sunTitleCtrl = TextEditingController();
  final _sunRefCtrl = TextEditingController();
  final _sunTextCtrl = TextEditingController();

  // Janazah
  final _janTitleCtrl = TextEditingController();
  final _janTimeCtrl = TextEditingController();
  final _janLocCtrl = TextEditingController();

  // Gumshuda
  final _gumTitleCtrl = TextEditingController();
  final _gumDetCtrl = TextEditingController();
  final _gumContactCtrl = TextEditingController();
  Uint8List? _gumImageBytes;
  final _uploadService = UploadService();

  // Announcement
  final _annItemTitleCtrl = TextEditingController();
  final _annItemDescCtrl = TextEditingController();
  String _annIcon = 'Megaphone';

  // Prayer
  List<Map<String, dynamic>> _prayerTimes = [];

  // Ramadan
  final _ramTaraweehCtrl = TextEditingController();
  final _ramFitraCtrl = TextEditingController();
  final _ramNoteCtrl = TextEditingController();

  // Donations
  final _donMonthCtrl = TextEditingController();
  final _donAmountCtrl = TextEditingController();
  final _expLabelCtrl = TextEditingController();
  final _expValCtrl = TextEditingController();
  final _causeTitleCtrl = TextEditingController();
  final _causeDescCtrl = TextEditingController();
  final _causeUpiCtrl = TextEditingController();
  String _causeBadge = 'Sadaqah';
  String? _causeQrBase64;

  // About
  final _memNameCtrl = TextEditingController();
  String _memRole = 'Sadr (President)';
  final _servTitleCtrl = TextEditingController();
  final _servDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 8, vsync: this);
    _initPrayerDefaults();
  }

  void _initPrayerDefaults() {
    _prayerTimes = [
      {'name': 'Fajr', 'azaan': '04:45 AM', 'time': '05:15 AM'},
      {'name': 'Dhuhr', 'azaan': '12:15 PM', 'time': '12:45 PM'},
      {'name': 'Asr', 'azaan': '03:30 PM', 'time': '04:00 PM'},
      {'name': 'Maghrib', 'azaan': '06:22 PM', 'time': '06:27 PM'},
      {'name': 'Isha', 'azaan': '07:45 PM', 'time': '08:15 PM'},
    ];
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _passwordCtrl.dispose();
    _brandNameCtrl.dispose();
    _homeStatusCtrl.dispose();
    _annTitleCtrl.dispose();
    _annDescCtrl.dispose();
    _sunTitleCtrl.dispose();
    _sunRefCtrl.dispose();
    _sunTextCtrl.dispose();
    _janTitleCtrl.dispose();
    _janTimeCtrl.dispose();
    _janLocCtrl.dispose();
    _gumTitleCtrl.dispose();
    _gumDetCtrl.dispose();
    _gumContactCtrl.dispose();
    _annItemTitleCtrl.dispose();
    _annItemDescCtrl.dispose();
    _ramTaraweehCtrl.dispose();
    _ramFitraCtrl.dispose();
    _ramNoteCtrl.dispose();
    _donMonthCtrl.dispose();
    _donAmountCtrl.dispose();
    _expLabelCtrl.dispose();
    _expValCtrl.dispose();
    _causeTitleCtrl.dispose();
    _causeDescCtrl.dispose();
    _causeUpiCtrl.dispose();
    _memNameCtrl.dispose();
    _servTitleCtrl.dispose();
    _servDescCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_passwordCtrl.text == '1234') {
      setState(() => _authorized = true);
      _loadConfig();
    } else {
      _snack('Incorrect password', isError: true);
    }
  }

  Future<void> _handleFingerprintLogin() async {
    final bio = BiometricService();
    if (!await bio.isAvailable()) {
      if (mounted) _snack('Biometric not available on this device', isError: true);
      return;
    }
    final ok = await bio.authenticate(reason: 'Unlock the Management Portal');
    if (ok && mounted) {
      setState(() => _authorized = true);
      _loadConfig();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<bool> _confirmCreate(String kind, String detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Post $kind?'),
        content: Text('$detail\n\nThis alert will be shown to all users and a push notification will be sent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.primary),
            child: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _loadConfig() async {
    try {
      final r = await Future.wait([
        _cmsService.getBranding().catchError((_) => <String, dynamic>{}),
        _cmsService.getHomeAnnouncement().catchError((_) => <String, dynamic>{}),
        _cmsService.getPrayerTimes().catchError((_) => []),
        _cmsService.getJumuah().catchError((_) => <String, dynamic>{}),
        _cmsService.getRamadan().catchError((_) => <String, dynamic>{}),
        _cmsService.getJanazahs().catchError((_) => []),
        _cmsService.getGumshudas().catchError((_) => []),
        _cmsService.getAnnouncements().catchError((_) => []),
        _cmsService.getDonationCauses().catchError((_) => []),
        _cmsService.getMonthlyDonations().catchError((_) => []),
        _cmsService.getExpenses().catchError((_) => []),
        _cmsService.getServices().catchError((_) => []),
        _cmsService.getTeamMembers().catchError((_) => []),
        _cmsService.getSunnahs().catchError((_) => []),
      ]);
      setState(() {
        _cfg = {
          'branding': r[0], 'home': r[1], 'prayerTimes': r[2], 'jumuah': r[3],
          'ramadan': r[4], 'janazahs': r[5], 'gumshudas': r[6], 'announcements': r[7],
          'donationCauses': r[8], 'monthlyDonations': r[9], 'expenses': r[10],
          'services': r[11], 'teamMembers': r[12], 'sunnahs': r[13],
        };
      });
      _populateControllers();
    } catch (_) {
      _initDefaults();
    }
  }

  void _initDefaults() {
    setState(() {
      _cfg = {
        'branding': {'name': 'Noor Al Masjid', 'primary': '142 76% 36%', 'secondary': '43 76% 58%'},
        'home': {'status': 'Open for Prayer', 'title': '', 'description': ''},
        'prayerTimes': <Map<String, dynamic>>[],
        'jumuah': {'time': '01:45 PM'},
        'ramadan': {'taraweeh': '08:30 PM', 'fitraRate': '150', 'note': ''},
        'janazahs': <Map<String, dynamic>>[],
        'gumshudas': <Map<String, dynamic>>[],
        'announcements': <Map<String, dynamic>>[],
        'donationCauses': <Map<String, dynamic>>[],
        'monthlyDonations': <Map<String, dynamic>>[],
        'expenses': <Map<String, dynamic>>[],
        'services': <Map<String, dynamic>>[],
        'teamMembers': <Map<String, dynamic>>[],
        'sunnahs': <Map<String, dynamic>>[],
      };
    });
    _populateControllers();
  }

  void _populateControllers() {
    final b = _cfg['branding'] as Map<String, dynamic>? ?? {};
    _brandNameCtrl.text = b['masjidName'] as String? ?? b['name'] as String? ?? 'Noor Al Masjid';
    _brandLogoUrl = b['logo'] as String?;
    final prim = (b['primaryColor'] as String? ?? b['primary'] as String? ?? '142 76% 36%').replaceAll('%', '').split(' ');
    if (prim.length == 3) { _primH = prim[0]; _primS = prim[1]; _primL = prim[2]; }
    final sec = (b['secondaryColor'] as String? ?? b['secondary'] as String? ?? '43 76% 58%').replaceAll('%', '').split(' ');
    if (sec.length == 3) { _secH = sec[0]; _secS = sec[1]; _secL = sec[2]; }
    context.read<ThemeProvider>().setBrandingColors('$_primH $_primS% $_primL%', '$_secH $_secS% $_secL%');

    final h = _cfg['home'] as Map<String, dynamic>? ?? {};
    _homeStatusCtrl.text = h['status'] as String? ?? 'Open for Prayer';
    _annTitleCtrl.text = h['title'] as String? ?? '';
    _annDescCtrl.text = h['description'] as String? ?? '';

    final r = _cfg['ramadan'] as Map<String, dynamic>? ?? {};
    _ramTaraweehCtrl.text = r['taraweeh'] as String? ?? '08:30 PM';
    _ramFitraCtrl.text = (r['fitraRate'] as num?)?.toString() ?? r['fitraRate'] as String? ?? '150';
    _ramNoteCtrl.text = r['note'] as String? ?? '';

    final pt = _cfg['prayerTimes'] as List<dynamic>?;
    if (pt != null && pt.isNotEmpty) {
      _prayerTimes = pt.cast<Map<String, dynamic>>();
    } else {
      _initPrayerDefaults();
    }
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    if (!_authorized) return _buildLogin();
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
            Tab(icon: Icon(Icons.access_time), text: 'Prayer'),
            Tab(icon: Icon(Icons.nights_stay), text: 'Ramadan'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'Sunnah'),
            Tab(icon: Icon(Icons.favorite), text: 'Donations'),
            Tab(icon: Icon(Icons.palette), text: 'Branding'),
            Tab(icon: Icon(Icons.people), text: 'About'),
          ],
        ),
        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            _buildHomeTab(),
            _buildAlertsTab(),
            _buildPrayerTab(),
            _buildRamadanTab(),
            _buildSunnahTab(),
            _buildDonationsTab(),
            _buildBrandingTab(),
            _buildAboutTab(),
          ]),
        ),
      ],
    );
  }

  Widget _buildLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.shield, size: 48, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 8),
          Text('Management Portal', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Admin Password',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Authorize', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          if (BiometricService().isSupported) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _handleFingerprintLogin,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock with Fingerprint'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
            ),
          ],
        ],
      ),
    );
  }

  // ========== BRANDING TAB ==========
  Widget _buildBrandingTab() {
    final theme = Theme.of(context);
    final primary = HSLColorConverter.fromHslString('$_primH $_primS% $_primL%');
    final secondary = HSLColorConverter.fromHslString('$_secH $_secS% $_secL%');
    return _section('Branding Settings', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live preview card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _logoPreview(primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _brandNameCtrl.text.isEmpty ? 'Noor Al Masjid' : _brandNameCtrl.text,
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text('Live preview', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _brandNameCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Masjid Display Name', prefixIcon: Icon(Icons.edit), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(_brandLogoBytes != null ? Icons.image : Icons.upload_file, size: 18),
                label: Text(_brandLogoBytes != null ? 'Logo Selected' : 'Upload Logo', style: const TextStyle(fontSize: 13)),
                onPressed: () async {
                  final picker = ImagePicker();
                  final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
                  if (f != null) {
                    final bytes = await f.readAsBytes();
                    setState(() => _brandLogoBytes = bytes);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            if (_brandLogoBytes != null || _brandLogoUrl != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => setState(() { _brandLogoBytes = null; _brandLogoUrl = null; }),
                tooltip: 'Remove logo',
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text('Theme Presets', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ThemePreset.presets.map((p) {
            final isActive = p.primaryHsl.replaceAll('%', '') == '$_primH $_primS $_primL';
            final pColor = HSLColorConverter.fromHslString(p.primaryHsl);
            final sColor = HSLColorConverter.fromHslString(p.secondaryHsl);
            return InkWell(
              onTap: () {
                setState(() {
                  final pp = p.primaryHsl.replaceAll('%', '').split(' ');
                  final ss = p.secondaryHsl.replaceAll('%', '').split(' ');
                  if (pp.length == 3) { _primH = pp[0]; _primS = pp[1]; _primL = pp[2]; }
                  if (ss.length == 3) { _secH = ss[0]; _secS = ss[1]; _secL = ss[2]; }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? theme.colorScheme.primary : theme.dividerColor,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 18, height: 18,
                      decoration: BoxDecoration(color: pColor, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 5),
                    Container(width: 18, height: 18,
                      decoration: BoxDecoration(color: sColor, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 6),
                    Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text('Custom Colors', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _hslSlider('Primary', primary, _primH, _primS, _primL, (h, s, l) {
          setState(() { _primH = h; _primS = s; _primL = l; });
        }),
        const SizedBox(height: 4),
        _hslSlider('Secondary', secondary, _secH, _secS, _secL, (h, s, l) {
          setState(() { _secH = h; _secS = s; _secL = l; });
        }),
        const SizedBox(height: 14),
        Row(
          children: [
            _colorPreview(primary),
            const SizedBox(width: 8),
            _colorPreview(secondary),
            const Spacer(),
            _miniBtn(Icons.palette_outlined, 'Custom', () => _pickCustomColor()),
            const SizedBox(width: 6),
            _miniBtn(Icons.shuffle, 'Random', () {
              setState(() {
                _primH = (DateTime.now().millisecondsSinceEpoch % 360).toString();
                _secH = ((DateTime.now().millisecondsSinceEpoch + 180) % 360).toString();
              });
            }),
            const SizedBox(width: 6),
            _miniBtn(Icons.restore, 'Default', () {
              setState(() {
                _primH = '142'; _primS = '76'; _primL = '36';
                _secH = '43'; _secS = '76'; _secL = '58';
              });
            }),
          ],
        ),
        const SizedBox(height: 20),
        _saveBtn(() async {
          final themeProvider = context.read<ThemeProvider>();
          String? logoUrl = _brandLogoUrl;
          if (_brandLogoBytes != null) {
            logoUrl = await _uploadService.uploadImage(_brandLogoBytes!, 'brand_${DateTime.now().millisecondsSinceEpoch}.png');
          }
          await _cmsService.updateBranding({
            'masjidName': _brandNameCtrl.text,
            'primaryColor': '$_primH $_primS% $_primL%',
            'secondaryColor': '$_secH $_secS% $_secL%',
            'logo': logoUrl,
          });
          themeProvider.setBrandingColors('$_primH $_primS% $_primL%', '$_secH $_secS% $_secL%');
          await context.read<MasjidProvider>().fetchCmsData();
        }),
      ],
    ));
  }

  Widget _logoPreview(Color fallback) {
    if (_brandLogoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_brandLogoBytes!, width: 52, height: 52, fit: BoxFit.cover),
      );
    }
    if (_brandLogoUrl != null && _brandLogoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_brandLogoUrl!, width: 52, height: 52, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _logoFallback(fallback)),
      );
    }
    return _logoFallback(fallback);
  }

  Widget _logoFallback(Color c) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.mosque_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _colorPreview(Color c) {
    return Container(width: 40, height: 40, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor)));
  }

  Widget _miniBtn(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _pickCustomColor() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _CustomColorDialog(initialPrimary: '$_primH $_primS% $_primL%', initialSecondary: '$_secH $_secS% $_secL%'),
    );
    if (result != null && mounted) {
      setState(() {
        final pp = result['primary']!.replaceAll('%', '').split(' ');
        final ss = result['secondary']!.replaceAll('%', '').split(' ');
        if (pp.length == 3) { _primH = pp[0]; _primS = pp[1]; _primL = pp[2]; }
        if (ss.length == 3) { _secH = ss[0]; _secS = ss[1]; _secL = ss[2]; }
      });
    }
  }

  Widget _hslSlider(String label, Color color, String h, String s, String l, Function(String, String, String) onChange) {
    final theme = Theme.of(context);
    double parse(String v) => double.tryParse(v) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: theme.dividerColor)),
              ),
              const SizedBox(width: 8),
              Text('$label', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          _hslSliderRow('H', 0, 360, parse(h).round(), (v) => onChange(v.toString(), s, l)),
          _hslSliderRow('S', 0, 100, parse(s).round(), (v) => onChange(h, v.toString(), l)),
          _hslSliderRow('L', 0, 100, parse(l).round(), (v) => onChange(h, s, v.toString())),
        ],
      ),
    );
  }

  Widget _hslSliderRow(String label, double min, double max, int value, Function(double) onChange) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value.toDouble().clamp(min, max),
              min: min,
              max: max,
              onChanged: onChange,
            ),
          ),
        ),
        SizedBox(width: 30, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
      ],
    );
  }

  // ========== HOME TAB ==========
  Widget _buildHomeTab() {
    return _section('Home Page Settings', Column(
      children: [
        TextFormField(
          controller: _homeStatusCtrl,
          decoration: const InputDecoration(labelText: 'Masjid Status', prefixIcon: Icon(Icons.info)),
        ),
        const SizedBox(height: 16),
        Text('Daily Popup Announcement', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _annTitleCtrl,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _annDescCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 20),
        _saveBtn(() async {
          await _cmsService.updateHomeAnnouncement({
            'status': _homeStatusCtrl.text,
            'title': _annTitleCtrl.text,
            'description': _annDescCtrl.text,
          });
        }),
      ],
    ));
  }

  // ========== SUNNAH TAB ==========
  Widget _buildSunnahTab() {
    final list = (_cfg['sunnahs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _section('Daily Sunnah Broadcaster', Column(
      children: [
          TextFormField(controller: _sunTitleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextFormField(controller: _sunRefCtrl, decoration: const InputDecoration(labelText: 'Reference (e.g. Bukhari)')),
          const SizedBox(height: 8),
          TextFormField(controller: _sunTextCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Sunnah Text')),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add to List', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () async {
                if (_sunTitleCtrl.text.isEmpty) return;
                try {
                  await _cmsService.createSunnah({
                    'title': _sunTitleCtrl.text,
                    'reference': _sunRefCtrl.text,
                    'text': _sunTextCtrl.text,
                  });
                  _cfg['sunnahs'] = await _cmsService.getSunnahs();
                  if (mounted) setState(() {});
                  _sunTitleCtrl.clear(); _sunRefCtrl.clear(); _sunTextCtrl.clear();
                  _snack('Sunnah added');
                } catch (e) {
                  _snack('Error adding: $e', isError: true);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No sunnahs yet.', style: TextStyle(fontStyle: FontStyle.italic)))
          else
            ...list.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(s['title'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(s['reference'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.campaign, color: Theme.of(context).colorScheme.secondary),
                      onPressed: () async {
                        try {
                          await _cmsService.setSunnahBroadcast((s['id'] as num).toInt());
                          if (mounted) _snack('Broadcasted: ${s['title']}');
                        } catch (e) {
                          if (mounted) _snack('Error broadcasting: $e', isError: true);
                        }
                      },
                      tooltip: 'Broadcast',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        try {
                          await _cmsService.deleteSunnah((s['id'] as num).toInt());
                          _cfg['sunnahs'] = await _cmsService.getSunnahs();
                          if (mounted) setState(() {});
                          _snack('Deleted');
                        } catch (e) {
                          _snack('Error deleting: $e', isError: true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            )),
      ],
    ));
  }

  // ========== ALERTS TAB ==========
  Widget _buildAlertsTab() {
    return _section('Alerts Management', DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Janazah'), Tab(text: 'Gumshuda'), Tab(text: 'Announcements'),
          ]),
          SizedBox(
            height: 500,
            child: TabBarView(children: [
              _buildJanazahSub(),
              _buildGumshudaSub(),
              _buildAnnouncementSub(),
            ]),
          ),
        ],
      ),
    ));
  }

  Widget _buildJanazahSub() {
    final list = (_cfg['janazahs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Janazah', list, (item) => [
      Text(item['title'] as String? ?? ''),
      Text(item['time'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
      Text(item['location'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
    ], Column(
      children: [
        TextFormField(controller: _janTitleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true)),
        const SizedBox(height: 6),
        TextFormField(controller: _janTimeCtrl, decoration: const InputDecoration(labelText: 'Time (e.g. After Dhuhr)', isDense: true)),
        const SizedBox(height: 6),
        TextFormField(controller: _janLocCtrl, decoration: const InputDecoration(labelText: 'Location', isDense: true)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add & Broadcast', style: TextStyle(fontSize: 12)),
          onPressed: () async {
            if (_janTitleCtrl.text.trim().isEmpty ||
                _janTimeCtrl.text.trim().isEmpty ||
                _janLocCtrl.text.trim().isEmpty) {
              _snack('Title, Time and Location are required', isError: true);
              return;
            }
            if (!await _confirmCreate('Janazah Alert',
                'Title: ${_janTitleCtrl.text}\nTime: ${_janTimeCtrl.text}\nLocation: ${_janLocCtrl.text}')) return;
            try {
              await _cmsService.createJanazah({
                'title': _janTitleCtrl.text,
                'time': _janTimeCtrl.text,
                'location': _janLocCtrl.text,
              });
              if (mounted) {
                context.read<MasjidProvider>().fetchCmsData();
                _loadConfig();
              }
              _janTitleCtrl.clear(); _janTimeCtrl.clear(); _janLocCtrl.clear();
              _snack('Janazah added & broadcast');
            } catch (e) {
              _snack('Error: $e', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        ),
      ],
    ), (item) async {
      try {
        await _cmsService.deleteJanazah(item['id'] as int);
        if (mounted) {
          context.read<MasjidProvider>().fetchCmsData();
          _loadConfig();
        }
        _snack('Janazah deleted');
      } catch (e) {
        _snack('Error deleting: $e', isError: true);
      }
    });
  }

  Widget _buildGumshudaSub() {
    final list = (_cfg['gumshudas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Missing Persons', list, (item) => [
      Text(item['title'] as String? ?? ''),
      Text(item['details'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 1),
      Text('Contact: ${item['contact'] as String? ?? ''}', style: Theme.of(context).textTheme.bodySmall),
    ], Column(
      children: [
        TextFormField(controller: _gumTitleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true)),
        const SizedBox(height: 6),
        TextFormField(controller: _gumDetCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Details', isDense: true)),
        const SizedBox(height: 6),
        TextFormField(controller: _gumContactCtrl, decoration: const InputDecoration(labelText: 'Contact Number', isDense: true)),
        const SizedBox(height: 6),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.image, size: 16),
              label: Text(_gumImageBytes != null ? 'Photo Added' : 'Add Photo', style: const TextStyle(fontSize: 11)),
              onPressed: () async {
                final picker = ImagePicker();
                final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
                if (f != null) {
                  final bytes = await f.readAsBytes();
                  setState(() => _gumImageBytes = bytes);
                }
              },
            ),
            if (_gumImageBytes != null)
              IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _gumImageBytes = null)),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Missing Person', style: TextStyle(fontSize: 12)),
          onPressed: () async {
            if (_gumTitleCtrl.text.trim().isEmpty ||
                _gumDetCtrl.text.trim().isEmpty ||
                _gumContactCtrl.text.trim().isEmpty) {
              _snack('Name, Details and Contact are required', isError: true);
              return;
            }
            if (!await _confirmCreate('Missing Person Alert',
                'Name: ${_gumTitleCtrl.text}\nDetails: ${_gumDetCtrl.text}\nContact: ${_gumContactCtrl.text}')) return;
            try {
              String? imageUrl;
              if (_gumImageBytes != null) {
                imageUrl = await _uploadService.uploadImage(_gumImageBytes!, 'gumshuda_${DateTime.now().millisecondsSinceEpoch}.jpg');
              }
              await _cmsService.createGumshuda({
                'title': _gumTitleCtrl.text,
                'details': _gumDetCtrl.text,
                'contact': _gumContactCtrl.text,
                'image': imageUrl,
              });
              if (mounted) {
                context.read<MasjidProvider>().fetchCmsData();
                _loadConfig();
              }
              _gumTitleCtrl.clear(); _gumDetCtrl.clear(); _gumContactCtrl.clear();
              _gumImageBytes = null;
              _snack('Missing person alert added & broadcast');
            } catch (e) {
              _snack('Error: $e', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        ),
      ],
    ), (item) async {
      try {
        await _cmsService.deleteGumshuda(item['id'] as int);
        if (mounted) {
          context.read<MasjidProvider>().fetchCmsData();
          _loadConfig();
        }
        _snack('Gumshuda deleted');
      } catch (e) {
        _snack('Error deleting: $e', isError: true);
      }
    });
  }

  Widget _buildAnnouncementSub() {
    final list = (_cfg['announcements'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Announcements', list, (item) => [
      Text(item['title'] as String? ?? ''),
      Text(item['description'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
    ], Column(
      children: [
        TextFormField(controller: _annItemTitleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true)),
        const SizedBox(height: 6),
        TextFormField(controller: _annItemDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', isDense: true)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _annIcon,
          decoration: const InputDecoration(labelText: 'Icon', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: ['Megaphone', 'Info', 'Heart', 'Sparkles', 'Users'].map((ic) => DropdownMenuItem(value: ic, child: Text(ic, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _annIcon = v ?? 'Megaphone'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Announcement', style: TextStyle(fontSize: 12)),
          onPressed: () async {
            if (_annItemTitleCtrl.text.trim().isEmpty ||
                _annItemDescCtrl.text.trim().isEmpty) {
              _snack('Title and Description are required', isError: true);
              return;
            }
            if (!await _confirmCreate('Announcement',
                'Title: ${_annItemTitleCtrl.text}\nDescription: ${_annItemDescCtrl.text}')) return;
            try {
              await _cmsService.createAnnouncement({
                'title': _annItemTitleCtrl.text,
                'description': _annItemDescCtrl.text,
                'icon': _annIcon,
              });
              if (mounted) {
                context.read<MasjidProvider>().fetchCmsData();
                _loadConfig();
              }
              _annItemTitleCtrl.clear(); _annItemDescCtrl.clear();
              _snack('Announcement added & broadcast');
            } catch (e) {
              _snack('Error: $e', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        ),
      ],
    ), (item) async {
      try {
        await _cmsService.deleteAnnouncement(item['id'] as int);
        if (mounted) {
          context.read<MasjidProvider>().fetchCmsData();
          _loadConfig();
        }
        _snack('Announcement deleted');
      } catch (e) {
        _snack('Error deleting: $e', isError: true);
      }
    });
  }

  // ========== PRAYER TAB ==========
  Widget _buildPrayerTab() {
    return _section('Daily Iqamah Timings', Column(
      children: [
          ..._prayerTimes.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _timeField('Azaan', p['azaan'] as String? ?? '', (t) {
                          setState(() => _prayerTimes[i] = {...p, 'azaan': t});
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _timeField('Iqamah', p['time'] as String? ?? '', (t) {
                          setState(() => _prayerTimes[i] = {...p, 'time': t});
                        })),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text('Jumu\'ah Prayer', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _timeField('Iqamah Time', (_cfg['jumuah'] as Map<String, dynamic>?)?['time'] as String? ?? '01:45 PM', (t) {
            setState(() { _cfg['jumuah'] = {'time': t}; });
          }),
          const SizedBox(height: 20),
          _saveBtn(() async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Save Prayer Times?'),
                content: const Text('Are you sure you want to save the updated prayer times? They will be shown to all users.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                ],
              ),
            );
            if (confirmed != true || !mounted) return;
            await _cmsService.updatePrayerTimes(_prayerTimes);
            final jumuah = _cfg['jumuah'] as Map<String, dynamic>?;
            if (jumuah != null) {
              await _cmsService.updateJumuah({'time': jumuah['time'] as String? ?? '01:45 PM'});
            }
            _snack('Prayer times saved');
          }),
      ],
    ));
  }

  Widget _timeField(String label, String val, Function(String) onChange) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: _parseTime(val),
        );
        if (t != null) onChange(_formatTime(t));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label, isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          suffixIcon: const Icon(Icons.access_time, size: 16),
        ),
        child: Text(val, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  TimeOfDay _parseTime(String t) {
    try {
      final parts = t.replaceAll(' AM', '').replaceAll(' PM', '').split(':');
      int h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (t.contains('PM') && h != 12) h += 12;
      if (t.contains('AM') && h == 12) h = 0;
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return const TimeOfDay(hour: 12, minute: 0);
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  // ========== RAMADAN TAB ==========
  Widget _buildRamadanTab() {
    return _section('Ramadan Settings', Column(
      children: [
        _timeField('Taraweeh Time', _ramTaraweehCtrl.text, (t) => _ramTaraweehCtrl.text = t),
        const SizedBox(height: 12),
        TextFormField(controller: _ramFitraCtrl, decoration: const InputDecoration(labelText: 'Fitra Rate (Rs)', prefixIcon: Icon(Icons.monetization_on))),
        const SizedBox(height: 12),
        TextFormField(controller: _ramNoteCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Ramadan Note')),
        const SizedBox(height: 20),
        _saveBtn(() async {
          await _cmsService.updateRamadan({
            'taraweeh': _ramTaraweehCtrl.text,
            'fitraRate': double.tryParse(_ramFitraCtrl.text) ?? 0,
            'note': _ramNoteCtrl.text,
          });
        }),
      ],
    ));
  }

  // ========== DONATIONS TAB ==========
  Widget _buildDonationsTab() {
    return _section('Donations Management', DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Collections'), Tab(text: 'Expenses'), Tab(text: 'Causes'),
          ]),
          SizedBox(
            height: 500,
            child: TabBarView(children: [
              _buildMonthlySub(),
              _buildExpensesSub(),
              _buildCausesSub(),
            ]),
          ),
        ],
      ),
    ));
  }

  Widget _buildMonthlySub() {
    final list = (_cfg['monthlyDonations'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Monthly Collections', list, (item) => [
      Text(item['month'] as String? ?? ''),
      Text('Rs ${item['amount'] as String? ?? ''}', style: Theme.of(context).textTheme.bodySmall),
    ], Row(
      children: [
        Expanded(child: TextFormField(controller: _donMonthCtrl, decoration: const InputDecoration(labelText: 'Month/Year', isDense: true))),
        const SizedBox(width: 6),
        Expanded(child: TextFormField(controller: _donAmountCtrl, decoration: const InputDecoration(labelText: 'Amount', isDense: true))),
        const SizedBox(width: 6),
        ElevatedButton(
          child: const Text('Add', style: TextStyle(fontSize: 11)),
          onPressed: () {
            setState(() {
              _cfg['monthlyDonations'] = [...list, {'month': _donMonthCtrl.text, 'amount': _donAmountCtrl.text, 'status': 'Received'}];
            });
            _donMonthCtrl.clear(); _donAmountCtrl.clear();
          },
        ),
      ],
    ), (item) {
      setState(() { _cfg['monthlyDonations'] = list.where((x) => x['month'] != item['month'] || x['amount'] != item['amount']).toList(); });
    });
  }

  Widget _buildExpensesSub() {
    final list = (_cfg['expenses'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Expenses', list, (item) => [
      Text(item['label'] as String? ?? ''),
      Text('Rs ${item['value'] as String? ?? ''}/mo', style: Theme.of(context).textTheme.bodySmall),
    ], Row(
      children: [
        Expanded(child: TextFormField(controller: _expLabelCtrl, decoration: const InputDecoration(labelText: 'Label', isDense: true))),
        const SizedBox(width: 6),
        Expanded(child: TextFormField(controller: _expValCtrl, decoration: const InputDecoration(labelText: 'Cost', isDense: true))),
        const SizedBox(width: 6),
        ElevatedButton(
          child: const Text('Add', style: TextStyle(fontSize: 11)),
          onPressed: () {
            setState(() {
              _cfg['expenses'] = [...list, {'label': _expLabelCtrl.text, 'value': _expValCtrl.text}];
            });
            _expLabelCtrl.clear(); _expValCtrl.clear();
          },
        ),
      ],
    ), (item) {
      setState(() { _cfg['expenses'] = list.where((x) => x['label'] != item['label']).toList(); });
    });
  }

  Widget _buildCausesSub() {
    final list = (_cfg['donationCauses'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Donation Causes', list, (item) => [
      Text(item['title'] as String? ?? ''),
      Text('UPI: ${item['upi'] as String? ?? ''}', style: Theme.of(context).textTheme.bodySmall),
      Text(item['badge'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
    ], Column(
      children: [
        TextFormField(controller: _causeTitleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true)),
        const SizedBox(height: 6),
        TextFormField(controller: _causeDescCtrl, decoration: const InputDecoration(labelText: 'Description', isDense: true)),
        const SizedBox(height: 6),
        TextFormField(controller: _causeUpiCtrl, decoration: const InputDecoration(labelText: 'UPI ID', isDense: true)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _causeBadge,
          decoration: const InputDecoration(labelText: 'Badge/Category', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: ['Sadaqah', 'Zakat', 'Maintenance', 'Welfare', 'Waqf'].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _causeBadge = v ?? 'Sadaqah'),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code, size: 16),
              label: Text(_causeQrBase64 != null ? 'QR Added' : 'Add QR', style: const TextStyle(fontSize: 11)),
              onPressed: () async {
                final picker = ImagePicker();
                final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
                if (f != null) {
                  final bytes = await f.readAsBytes();
                  setState(() => _causeQrBase64 = base64Encode(bytes));
                }
              },
            ),
            if (_causeQrBase64 != null)
              IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _causeQrBase64 = null)),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Cause', style: TextStyle(fontSize: 12)),
          onPressed: () {
            setState(() {
              _cfg['donationCauses'] = [...list, {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'title': _causeTitleCtrl.text, 'description': _causeDescCtrl.text,
                'upi': _causeUpiCtrl.text, 'badge': _causeBadge, 'qrImage': _causeQrBase64,
              }];
            });
            _causeTitleCtrl.clear(); _causeDescCtrl.clear(); _causeUpiCtrl.clear();
            _causeQrBase64 = null;
            _snack('Cause added');
          },
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        ),
      ],
    ), (item) {
      setState(() { _cfg['donationCauses'] = list.where((x) => x['id'] != item['id']).toList(); });
    });
  }

  // ========== ABOUT TAB ==========
  Widget _buildAboutTab() {
    return _section('About Page Management', DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Management Team'), Tab(text: 'Services'),
          ]),
          SizedBox(
            height: 500,
            child: TabBarView(children: [
              _buildTeamSub(),
              _buildServiceSub(),
            ]),
          ),
        ],
      ),
    ));
  }

  Widget _buildTeamSub() {
    final list = (_cfg['teamMembers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Team Members', list, (item) => [
      Text(item['name'] as String? ?? ''),
      Text(item['role'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
    ], Row(
      children: [
        Expanded(child: TextFormField(controller: _memNameCtrl, decoration: const InputDecoration(labelText: 'Name', isDense: true))),
        const SizedBox(width: 6),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _memRole,
            decoration: const InputDecoration(labelText: 'Role', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            items: ['Sadr (President)', 'Head Imam', 'Naib Imam', 'Secretary'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (v) => setState(() => _memRole = v ?? 'Sadr (President)'),
          ),
        ),
        const SizedBox(width: 6),
        ElevatedButton(
          child: const Text('Add', style: TextStyle(fontSize: 11)),
          onPressed: () {
            setState(() {
              _cfg['teamMembers'] = [...list, {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': _memNameCtrl.text, 'role': _memRole,
                'email': '', 'mobile': '', 'responsibilities': [], 'image': '',
              }];
            });
            _memNameCtrl.clear();
            _snack('Member added');
          },
        ),
      ],
    ), (item) {
      setState(() { _cfg['teamMembers'] = list.where((x) => x['id'] != item['id']).toList(); });
    });
  }

  Widget _buildServiceSub() {
    final list = (_cfg['services'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return _subList('Services', list, (item) => [
      Text(item['title'] as String? ?? ''),
      Text(item['description'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 1),
    ], Row(
      children: [
        Expanded(child: TextFormField(controller: _servTitleCtrl, decoration: const InputDecoration(labelText: 'Title', isDense: true))),
        const SizedBox(width: 6),
        Expanded(child: TextFormField(controller: _servDescCtrl, decoration: const InputDecoration(labelText: 'Description', isDense: true))),
        const SizedBox(width: 6),
        ElevatedButton(
          child: const Text('Add', style: TextStyle(fontSize: 11)),
          onPressed: () {
            setState(() {
              _cfg['services'] = [...list, {'title': _servTitleCtrl.text, 'description': _servDescCtrl.text, 'icon': 'Heart'}];
            });
            _servTitleCtrl.clear(); _servDescCtrl.clear();
            _snack('Service added');
          },
        ),
      ],
    ), (item) {
      setState(() { _cfg['services'] = list.where((x) => x['title'] != item['title']).toList(); });
    });
  }

  // ========== HELPERS ==========
  Widget _section(String title, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _saveBtn(Function() onSave) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w900)),
        onPressed: () async {
          try {
            await onSave();
            if (mounted) context.read<MasjidProvider>().fetchCmsData();
            _snack('Saved!');
          } catch (e) {
            _snack('Error saving: $e', isError: true);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _subList(
    String label,
    List<Map<String, dynamic>> items,
    List<Widget> Function(Map<String, dynamic>) itemBuilder,
    Widget addForm,
    Function(Map<String, dynamic>) onDelete,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          addForm,
          const Divider(height: 20),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No $label yet.', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            )
          else
            ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                title: itemBuilder(item).first,
                subtitle: itemBuilder(item).length > 1 ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: itemBuilder(item).skip(1).toList(),
                ) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => onDelete(item),
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  final String initialPrimary;
  final String initialSecondary;
  const _CustomColorDialog({required this.initialPrimary, required this.initialSecondary});

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late double _pH, _pS, _pL;
  late double _sH, _sS, _sL;

  @override
  void initState() {
    super.initState();
    List<double> parse(String v, double def) {
      final parts = v.replaceAll('%', '').split(' ');
      return parts.length == 3 ? [double.parse(parts[0]), double.parse(parts[1]), double.parse(parts[2])] : [def, 50, 50];
    }

    final p = parse(widget.initialPrimary, 142);
    final s = parse(widget.initialSecondary, 43);
    _pH = p[0]; _pS = p[1]; _pL = p[2];
    _sH = s[0]; _sS = s[1]; _sL = s[2];
  }

  String _hsl(double h, double s, double l) => '${h.round()} ${s.round()}% ${l.round()}%';

  Widget _slider(String label, Color color, double value, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 42, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
        Expanded(
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 30, child: Text('${value.round()}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
      ],
    );
  }

  Widget _colorEditor(String name, Color color, double h, double s, double l, void Function(double, double, double) apply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6), border: Border.all(color: Theme.of(context).dividerColor))),
            const SizedBox(width: 8),
            Text('$name Color', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        _HslPickerBox(
          hue: h,
          saturation: s,
          lightness: l,
          onChanged: (ns, nl) => setState(() => apply(h, ns, nl)),
        ),
        const SizedBox(height: 6),
        _HueBar(
          hue: h,
          onChanged: (nh) => setState(() => apply(nh, s, l)),
        ),
        const SizedBox(height: 6),
        _slider('Hue', color, h, 360, (v) => setState(() => apply(v, s, l))),
        _slider('Sat', color, s, 100, (v) => setState(() => apply(h, v, l))),
        _slider('Lgt', color, l, 100, (v) => setState(() => apply(h, s, v))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pColor = HSLColorConverter.fromHslString(_hsl(_pH, _pS, _pL));
    final sColor = HSLColorConverter.fromHslString(_hsl(_sH, _sS, _sL));
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.palette_outlined, size: 22),
          const SizedBox(width: 8),
          const Text('Custom Colors', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _colorEditor('Primary', pColor, _pH, _pS, _pL, (h, s, l) { _pH = h; _pS = s; _pL = l; }),
              const Divider(height: 24),
              _colorEditor('Secondary', sColor, _sH, _sS, _sL, (h, s, l) { _sH = h; _sS = s; _sL = l; }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {'primary': _hsl(_pH, _pS, _pL), 'secondary': _hsl(_sH, _sS, _sL)}),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _HslPickerBox extends StatefulWidget {
  final double hue;
  final double saturation;
  final double lightness;
  final void Function(double saturation, double lightness) onChanged;
  const _HslPickerBox({required this.hue, required this.saturation, required this.lightness, required this.onChanged});

  @override
  State<_HslPickerBox> createState() => _HslPickerBoxState();
}

class _HslPickerBoxState extends State<_HslPickerBox> {
  double _w = 0;
  double _h = 0;

  void _update(Offset local) {
    if (_w == 0 || _h == 0) return;
    final dx = (local.dx / _w).clamp(0.0, 1.0);
    final dy = (local.dy / _h).clamp(0.0, 1.0);
    widget.onChanged(dx * 100, (1 - dy) * 100);
  }

  @override
  Widget build(BuildContext context) {
    final baseHue = (widget.hue % 360).toDouble();
    final saturation = (widget.saturation / 100).clamp(0.0, 1.0);
    final lightness = (widget.lightness / 100).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        _w = constraints.maxWidth;
        _h = constraints.maxHeight;
        return GestureDetector(
          onPanDown: (d) => _update(d.localPosition),
          onPanUpdate: (d) => _update(d.localPosition),
          onTapDown: (d) => _update(d.localPosition),
          child: Stack(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      HSLColor.fromAHSL(1, baseHue, 1, 0.5).toColor(),
                      Colors.white,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 1],
                  ),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: saturation * (_w - 24),
                top: (1 - lightness) * (180 - 24),
                child: IgnorePointer(
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSLColor.fromAHSL(1, baseHue, saturation, lightness).toColor(),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HueBar extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;
  const _HueBar({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (d) => onChanged((d.localPosition.dx / w).clamp(0.0, 1.0) * 360),
          onPanUpdate: (d) => onChanged((d.localPosition.dx / w).clamp(0.0, 1.0) * 360),
          onTapDown: (d) => onChanged((d.localPosition.dx / w).clamp(0.0, 1.0) * 360),
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: List.generate(7, (i) => HSLColor.fromAHSL(1, i * 60.0, 1, 0.5).toColor()),
              ),
            ),
          ),
        );
      },
    );
  }
}
