import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../common/sign_in_popup.dart';

class TasbihCounter extends StatefulWidget {
  const TasbihCounter({super.key});

  @override
  State<TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends State<TasbihCounter> with TickerProviderStateMixin {
  int _count = 0;
  String _selectedDhikr = 'SubhanAllah';
  int? _targetGoal;
  List<Map<String, dynamic>> _userAdhkars = [];
  int _pulseIndex = -1;
  late AnimationController _pulseCtrl;
  final ScrollController _dhikrCtrl = ScrollController();

  static const int beadsPerSet = 33;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dhikrCtrl.dispose();
    super.dispose();
  }

  void _selectDhikr(String title) {
    setState(() => _selectedDhikr = title);
    _saveSession();
    final index = _allAdhkars.indexWhere((a) => a['title'] == title);
    if (index >= 0) _scrollDhikrToCenter(index);
  }

  void _scrollDhikrToCenter(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dhikrCtrl.hasClients) return;
      const pillWidth = 140.0;
      const gap = 6.0;
      final vw = _dhikrCtrl.position.viewportDimension;
      final target = (index * (pillWidth + gap) + pillWidth / 2) - (vw / 2);
      _dhikrCtrl.animateTo(
        target.clamp(0, _dhikrCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final adhkars = await UserService().getAdhkars();
      _userAdhkars = adhkars.cast<Map<String, dynamic>>();
    } catch (_) {
      final saved = prefs.getStringList('tasbih_custom_adhkars');
      if (saved != null) {
        _userAdhkars = saved.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    _targetGoal = prefs.getInt('tasbih_target_goal');
    final sessionCount = prefs.getInt('tasbih_count') ?? 0;
    final sessionDhikr = prefs.getString('tasbih_dhikr') ?? 'SubhanAllah';
    _count = sessionCount;
    _selectedDhikr = sessionDhikr;
    setState(() {});
    final index = _allAdhkars.indexWhere((a) => a['title'] == sessionDhikr);
    if (index >= 0) _scrollDhikrToCenter(index);
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', _count);
    await prefs.setString('tasbih_dhikr', _selectedDhikr);
  }

  void _increment() {
    final currentIdx = _count % beadsPerSet;
    setState(() {
      _count++;
      _pulseIndex = currentIdx;
    });
    HapticFeedback.mediumImpact();
    _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
    _saveSession();

    if (_count % beadsPerSet == 0) {
      HapticFeedback.heavyImpact();
      if (_targetGoal != null && _count >= _targetGoal!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('MashaAllah! Goal reached! 🎉'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (_count % beadsPerSet == 0 && _allAdhkars.isNotEmpty) {
      final currentIdx = _allAdhkars.indexWhere((d) => d['title'] == _selectedDhikr);
      if (currentIdx >= 0) {
        final nextIdx = (currentIdx + 1) % _allAdhkars.length;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _selectDhikr(_allAdhkars[nextIdx]['title']!);
        });
      }
    }
  }

  void _decrement() {
    if (_count <= 0) return;
    setState(() => _count--);
    HapticFeedback.lightImpact();
    _saveSession();
  }

  Future<void> _confirmFinishSet() async {
    if (_count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Set?'),
        content: Text('Save $_count × $_selectedDhikr as a set?\nSet $_currentSet • $_beadCount / $beadsPerSet'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.secondary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _finishSet();
  }

  Future<void> _finishSet() async {
    if (_count == 0) return;
    final count = _count;
    final dhikr = _selectedDhikr;

    if (!context.read<AuthProvider>().isAuthenticated) {
      final ok = await ensureSignedIn(context, action: 'your tasbih sets');
      if (!ok) {
        if (!context.mounted) return;
        setState(() => _count = 0);
        _saveSession();
        return;
      }
      return;
    }

    try {
      await UserService().createTasbihLog({'dhikr': dhikr, 'count': count});
      _showSavedSnack('Saved');
    } catch (_) {
      _showSavedSnack('Could not save — check your connection');
    }
    setState(() => _count = 0);
    _saveSession();
  }

  void _showSavedSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmReset() async {
    if (_count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Tasbih?'),
        content: Text('Clear current count ($_count) for $_selectedDhikr?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _count = 0);
    _saveSession();
  }

  // ignore: unused_element
  void _reset() => setState(() => _count = 0);

  List<Map<String, dynamic>> get _allAdhkars => [
    ...AppConstants.commonAdhkars,
    ..._userAdhkars,
  ];

  String get _arabicDhikr {
    for (final a in _allAdhkars) {
      if (a['title'] == _selectedDhikr) return a['arabic'] as String? ?? '';
    }
    return '';
  }

  int get _currentSet => (_count ~/ beadsPerSet) + 1;
  int get _beadCount => _count % beadsPerSet;

  @override
  Widget build(BuildContext context) {
    final progress = _targetGoal != null ? (_count / _targetGoal!).clamp(0, 1) : _beadCount / beadsPerSet.toDouble();
    final isGoalReached = _targetGoal != null && _count >= _targetGoal!;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.04),
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(fontSize: 12, fontFamily: 'Alegreya', color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 24, height: 1, color: primary.withValues(alpha: 0.15)),
                    const SizedBox(width: 10),
                    Text('Tasbīḥ', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(width: 10),
                    Container(width: 24, height: 1, color: primary.withValues(alpha: 0.15)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Remembrance of Allah',
                  style: theme.textTheme.bodySmall?.copyWith(color: secondary.withValues(alpha: 0.7), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Dhikr display — centered prominent
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child),
            ),
            child: Column(
              key: ValueKey(_selectedDhikr),
              children: [
                if (_arabicDhikr.isNotEmpty)
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [secondary, primary],
                    ).createShader(bounds),
                    child: Text(_arabicDhikr,
                      style: TextStyle(fontSize: 34, fontFamily: 'Alegreya', fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondary.withValues(alpha: 0.12), primary.withValues(alpha: 0.06)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: secondary.withValues(alpha: 0.15)),
                  ),
                  child: Text(_selectedDhikr,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(_targetGoal != null ? 'Goal: $_targetGoal' : 'Progress',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text('${(progress * 100).toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.toDouble().clamp(0.001, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: isGoalReached
                              ? [Colors.green, Colors.green.shade300]
                              : [primary, primary.withValues(alpha: 0.6)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Middle content (non-scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: secondary, size: 14),
                        const SizedBox(width: 6),
                        Text('Dhikr', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/saved-tasbihs'),
                          child: Row(
                            children: [
                              Text('Saved', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 14, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 62,
                    child: ListView(
                      controller: _dhikrCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      children: [
                        ..._allAdhkars.asMap().entries.map((e) => _buildDhikrPill(e.value, theme, e.key)),
                        const SizedBox(width: 6),
                        _buildAddPill(theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Bottom counter — thumb zone with ripple
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _increment,
              onLongPress: _confirmReset,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              splashColor: primary.withValues(alpha: 0.12),
              highlightColor: primary.withValues(alpha: 0.05),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -6)),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isGoalReached ? Colors.green.withValues(alpha: 0.4) : primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isGoalReached ? Colors.green : primary).withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedScale(
                        scale: _pulseCtrl.isAnimating ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isGoalReached
                                ? [Colors.green, Colors.green.shade300]
                                : [primary, secondary],
                          ).createShader(bounds),
                          child: Text('$_count',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900, fontSize: 52,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildBeadRow(theme),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_allAdhkars.any((d) => d['title'] == _selectedDhikr))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.loop_rounded, size: 10, color: secondary),
                                  const SizedBox(width: 4),
                                  Text('Set $_currentSet',
                                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: secondary),
                                  ),
                                ],
                              ),
                            ),
                          if (_allAdhkars.any((d) => d['title'] == _selectedDhikr))
                            const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$_beadCount / $beadsPerSet',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10, fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isGoalReached)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.green, Colors.green.shade400]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.celebration_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Goal Reached!',
                                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Controls at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(
              children: [
                _miniBtn(Icons.refresh_rounded, Colors.orange, _confirmReset),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _count == 0 ? null : _confirmFinishSet,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Set', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                        disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _miniBtn(Icons.track_changes_rounded, secondary, () => _showGoalDialog(context)),
                const SizedBox(width: 8),
                if (_targetGoal != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('/$_targetGoal',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: primary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeadRow(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        alignment: WrapAlignment.center,
        children: List.generate(beadsPerSet, (i) {
          final filled = i < _beadCount;
          final isCurrent = i == _pulseIndex && filled;
          return AnimatedContainer(
            duration: Duration(milliseconds: isCurrent ? 200 : 300),
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: filled
                  ? LinearGradient(
                      colors: isCurrent
                          ? [primary, primary.withValues(alpha: 0.7)]
                          : [primary.withValues(alpha: 0.8), primary.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: filled ? null : Colors.transparent,
              border: Border.all(
                color: filled ? Colors.transparent : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: isCurrent && filled
                  ? [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 6)]
                  : filled
                      ? [BoxShadow(color: primary.withValues(alpha: 0.15), blurRadius: 3)]
                      : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDhikrPill(Map<String, dynamic> a, ThemeData theme, int index) {
    final isSelected = _selectedDhikr == a['title'];
    final isCustom = index >= AppConstants.commonAdhkars.length;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _selectDhikr(a['title'] as String? ?? ''),
        onLongPress: isCustom ? () => _confirmDeleteDhikr(a) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [primary, primary.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isSelected ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (a['arabic'] != null)
                    Directionality(textDirection: TextDirection.rtl,
                      child: Text(a['arabic'] as String? ?? '',
                        style: TextStyle(fontFamily: 'Alegreya', fontSize: 15,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                    )
                  else if (isCustom)
                    GestureDetector(
                      onTap: () => _confirmDeleteDhikr(a),
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 11, color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(a['title'] as String? ?? '',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white.withValues(alpha: 0.9) : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDhikr(Map<String, dynamic> a) async {
    final title = a['title'] as String? ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Adhkar?'),
        content: Text('Delete "$title" from your list?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final id = a['id'];
    try {
      if (id != null) {
        await UserService().deleteAdhkar(id as int);
      }
      setState(() {
        _userAdhkars = _userAdhkars.where((x) => x['title'] != title).toList();
        if (_selectedDhikr == title) _selectedDhikr = AppConstants.commonAdhkars.first['title']!;
      });
      _saveSession();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete — check your connection')),
      );
    }
  }

  Widget _buildAddPill(ThemeData theme) {
    final secondary = theme.colorScheme.secondary;
    return GestureDetector(
      onTap: () => _showAddDhikrDialog(context),
      child: Container(
        width: 52,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: secondary.withValues(alpha: 0.6)),
            Text('New', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: secondary.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: color,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Daily Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [33, 99, 100, 300, 500].map((v) => ChoiceChip(
                label: Text('$v'),
                selected: _targetGoal == v,
                onSelected: (_) async {
                  Navigator.of(dialogCtx).pop();
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (!mounted || !context.mounted) return;
                  // ignore: use_build_context_synchronously
                  final ok = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx2) => AlertDialog(
                      title: const Text('Set Goal?'),
                      content: Text('Set daily goal to $v tasbih?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx2).pop(false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx2).colorScheme.secondary),
                          onPressed: () => Navigator.of(ctx2).pop(true),
                          child: const Text('Set', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !mounted) return;
                  setState(() => _targetGoal = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('tasbih_target_goal', v);
                },
              )).toList(),
            ),
            if (_targetGoal != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (!mounted || !context.mounted) return;
                  // ignore: use_build_context_synchronously
                  final ok = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx2) => AlertDialog(
                      title: const Text('Clear Goal?'),
                      content: Text('Remove daily goal ($_targetGoal)?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx2).pop(false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                          onPressed: () => Navigator.of(ctx2).pop(true),
                          child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !mounted) return;
                  setState(() => _targetGoal = null);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('tasbih_target_goal');
                },
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: Text('Clear Goal ($_targetGoal)', style: const TextStyle(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddDhikrDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final arabicCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Adhkar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (English)')),
            const SizedBox(height: 8),
            TextField(controller: arabicCtrl, decoration: const InputDecoration(labelText: 'Arabic Text')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final arabic = arabicCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a title')));
                return;
              }
              final existing = _allAdhkars.indexWhere((a) =>
                (a['title'] as String? ?? '').toLowerCase() == title.toLowerCase());
              if (existing >= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('"$title" already exists'), backgroundColor: Colors.orange.shade700),
                );
                return;
              }
              if (!context.read<AuthProvider>().isAuthenticated) {
                final ok = await ensureSignedIn(context, action: 'custom adhkar');
                if (!ok || !context.mounted) return;
              }
              final entry = {'title': title, 'arabic': arabic, 'transliteration': ''};
              try {
                await UserService().createAdhkar(entry);
                final adhkars = await UserService().getAdhkars();
                setState(() => _userAdhkars = adhkars.cast<Map<String, dynamic>>());
              } catch (_) {
                setState(() => _userAdhkars = [..._userAdhkars, entry]);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
