import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _surahs = [];
  bool _loading = true;
  String _searchQuery = '';
  Map<String, bool> _completedAyats = {};
  Map<String, int> _surahCheckpoints = {};
  Map<String, int> _juzCheckpoints = {};
  Set<int> _completedJuz = {};

  @override
  void initState() {
    super.initState();
    _completedAyats = {};
    _surahCheckpoints = {};
    _juzCheckpoints = {};
    _completedJuz = {};
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadSurahs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    try {
      final res = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _surahs = List<Map<String, dynamic>>.from(data['data'] as List);
      }
    } catch (_) {
      _surahs = List.generate(114, (i) => {
        'number': i + 1, 'englishName': 'Surah ${i + 1}', 'name': 'سورة',
        'englishNameTranslation': '', 'numberOfAyahs': 7, 'revelationType': 'Meccan',
      });
    }
    await _loadProgress();
    setState(() => _loading = false);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _surahCheckpoints = {};
    for (int i = 1; i <= 114; i++) {
      final v = prefs.getInt('surah_cp_$i');
      if (v != null && v > 0) _surahCheckpoints[i.toString()] = v;
    }
    _juzCheckpoints = {};
    for (int i = 1; i <= 30; i++) {
      final v = prefs.getInt('juz_cp_$i');
      if (v != null && v > 0) _juzCheckpoints[i.toString()] = v;
    }
    _completedJuz = {};
    for (int i = 1; i <= 30; i++) {
      if (prefs.getBool('juz_completed_$i') == true) _completedJuz.add(i);
    }
    final keys = prefs.getStringList('completed_ayats');
    if (keys != null) {
      _completedAyats = {for (final k in keys) k: true};
    }
  }

  Future<void> _setJuzComplete(int juzNum, bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('juz_completed_$juzNum', complete);
    setState(() {
      if (complete) {
        _completedJuz.add(juzNum);
      } else {
        _completedJuz.remove(juzNum);
      }
    });
  }

  Future<void> _saveJuzCheckpoint(int juzNum, int ayahIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('juz_cp_$juzNum', ayahIndex + 1);
    _juzCheckpoints[juzNum.toString()] = ayahIndex + 1;
  }

  Future<void> _saveCheckpoint(int surahNum, int ayahNum) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('surah_cp_$surahNum', ayahNum);
    setState(() => _surahCheckpoints[surahNum.toString()] = ayahNum);
  }

  Future<void> _toggleAyahComplete(String key, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    if (completed) {
      _completedAyats[key] = true;
    } else {
      _completedAyats.remove(key);
    }
    await prefs.setStringList('completed_ayats', _completedAyats.keys.toList());
  }

  List<Map<String, dynamic>> get _filteredSurahs {
    if (_searchQuery.isEmpty) return _surahs;
    return _surahs.where((s) =>
      (s['englishName'] as String?)?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
      s['number'].toString() == _searchQuery
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Al-Quran', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              ),
              Text('${_surahCheckpoints.length}/114 • ${_juzCheckpoints.length}/30', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700,
              )),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: List.generate(2, (i) {
                final labels = ['Surahs', 'Juz'];
                final icons = [Icons.menu_book_rounded, Icons.auto_stories_rounded];
                final active = _tabCtrl.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabCtrl.animateTo(i)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: active
                            ? LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: active ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: active
                            ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[i], size: 15, color: active ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 5),
                          Text(labels[i],
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: active ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildSurahTab(context),
              _buildJuzTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurahTab(BuildContext context) {
    if (_loading) return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('لَا إِلٰهَ إِلَّا اللهُ مُحَمَّدٌ رَسُولُ اللهِ',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Alegreya'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );

    return Column(
      children: [
        if (_surahCheckpoints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset Surah Progress?'),
                      content: const Text('This will clear all surah checkpoints.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) await _resetSurahProgress();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Reset Surah', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search surah...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filteredSurahs.length,
            itemBuilder: (_, i) {
              final s = _filteredSurahs[i];
              final num = s['number'] as int;
              final checkpoint = _surahCheckpoints[num.toString()] ?? 0;
              final ayahs = s['numberOfAyahs'] as int? ?? 0;
              final pct = ayahs > 0 ? checkpoint / ayahs : 0.0;
              final isCompleted = checkpoint >= ayahs;

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openSurahReader(context, s),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.withValues(alpha: 0.15) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('${s['number']}', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                          ))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(s['englishName'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                  ),
                                  Text(s['name'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'Alegreya', color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.w700,
                                  )),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${s['englishNameTranslation']} • ${s['numberOfAyahs']} ayahs • ${s['revelationType']}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              if (checkpoint > 0) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 4,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(isCompleted ? Colors.green : Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isCompleted)
                          const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, color: Colors.green, size: 20)),
                        if (checkpoint > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: GestureDetector(
                              onTap: () => _confirmResetSurah(context, s),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.restart_alt, color: Colors.orange, size: 18),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJuzTab(BuildContext context) {
    if (_loading) return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Alegreya'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
    return Column(
      children: [
        if (_juzCheckpoints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset Juz Progress?'),
                      content: const Text('This will clear all para checkpoints.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) await _resetJuzProgress();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Reset Juz', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: 30,
            itemBuilder: (_, i) {
              final juzNum = i + 1;
              final isCompleted = _completedJuz.contains(juzNum);
              return Card(
                color: isCompleted ? Colors.green.withValues(alpha: 0.15) : null,
                child: InkWell(
                  onTap: () => _openJuzReader(context, juzNum),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${juzNum}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                        )),
                        const SizedBox(height: 4),
                        Text('Para $juzNum', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isCompleted ? Colors.green.shade700 : Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        )),
                        const SizedBox(height: 2),
                        Text(AppConstants.juzNames[i], style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openJuzReader(BuildContext context, int juzNum) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _JuzReaderDialog(
        juzNum: juzNum,
        completedAyats: _completedAyats,
        onToggleAyah: _toggleAyahComplete,
        initialIndex: (_juzCheckpoints[juzNum.toString()] ?? 1) - 1,
        onSaveCheckpoint: (idx) => _saveJuzCheckpoint(juzNum, idx),
        onJuzComplete: (complete) => _setJuzComplete(juzNum, complete),
      ),
    );
  }

  Future<void> _resetSurahProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= 114; i++) {
      await prefs.remove('surah_cp_$i');
    }
    setState(() => _surahCheckpoints.clear());
  }

  Future<void> _resetJuzProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= 30; i++) {
      await prefs.remove('juz_cp_$i');
      await prefs.remove('juz_completed_$i');
    }
    setState(() {
      _juzCheckpoints.clear();
      _completedJuz.clear();
    });
  }

  void _openSurahReader(BuildContext context, Map<String, dynamic> surah) {
    final surahNum = surah['number'] as int;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SurahReaderDialog(
        surah: surah,
        surahNum: surahNum,
        checkpoint: _surahCheckpoints[surahNum.toString()] ?? 0,
        onSaveCheckpoint: (ayah) => _saveCheckpoint(surahNum, ayah),
        onToggleAyah: _toggleAyahComplete,
        onResetAll: _resetSurahProgress,
        completedAyats: _completedAyats,
      ),
    );
  }

  Future<void> _confirmResetSurah(BuildContext context, Map<String, dynamic> surah) async {
    final num = surah['number'] as int;
    final name = surah['englishName'] as String? ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Surah Progress?'),
        content: Text('Clear checkpoint and completed ayahs for $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('surah_cp_$num');
    final keys = prefs.getStringList('completed_ayats');
    if (keys != null) {
      final filtered = keys.where((k) => !k.startsWith('$num:')).toList();
      await prefs.setStringList('completed_ayats', filtered);
      setState(() {
        _completedAyats.removeWhere((k, _) => k.startsWith('$num:'));
        _surahCheckpoints.remove(num.toString());
      });
    } else {
      setState(() {
        _surahCheckpoints.remove(num.toString());
        _completedAyats.removeWhere((k, _) => k.startsWith('$num:'));
      });
    }
    if (mounted) _snack('Progress reset for $name');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}

enum TranslationMode { arabicOnly, arabicEnglish, arabicUrdu, both }

class _SurahReaderDialog extends StatefulWidget {
  final Map<String, dynamic> surah;
  final int surahNum;
  final int checkpoint;
  final Future<void> Function(int ayah) onSaveCheckpoint;
  final Future<void> Function(String key, bool completed) onToggleAyah;
  final Future<void> Function() onResetAll;
  final Map<String, bool> completedAyats;

  const _SurahReaderDialog({
    required this.surah, required this.surahNum, required this.checkpoint,
    required this.onSaveCheckpoint, required this.onToggleAyah, required this.onResetAll,
    required this.completedAyats,
  });

  @override
  State<_SurahReaderDialog> createState() => _SurahReaderDialogState();
}

class _SurahReaderDialogState extends State<_SurahReaderDialog> {
  List<Map<String, dynamic>> _ayahs = [];
  Map<String, String> _enTranslations = {};
  Map<String, String> _urTranslations = {};
  bool _loading = true;
  late Map<String, bool> _completed;
  int _lastReadAyah = 0;
  TranslationMode _mode = TranslationMode.both;

  @override
  void initState() {
    super.initState();
    _completed = Map.from(widget.completedAyats);
    _lastReadAyah = widget.checkpoint;
    _loadAyahs();
  }

  Future<void> _loadAyahs() async {
    try {
      final res = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.surahNum}/editions/quran-uthmani,en.sahih,ur.maududi'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final editions = data['data'] as List;
        if (editions.length >= 3) {
          final arabic = editions[0]['ayahs'] as List;
          final english = editions[1]['ayahs'] as List;
          final urdu = editions[2]['ayahs'] as List;
          _ayahs = List<Map<String, dynamic>>.from(arabic);
          for (final e in english) {
            _enTranslations[e['numberInSurah'].toString()] = e['text'] as String;
          }
          for (final u in urdu) {
            _urTranslations[u['numberInSurah'].toString()] = u['text'] as String;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _getAyahKey(int surah, int ayah) => '$surah:$ayah';

  Future<void> _completeSurah() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Complete?'),
        content: Text('Mark all ${_ayahs.length} ayahs of ${widget.surah['englishName']} as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final ayah in _ayahs) {
      final ayahNum = ayah['numberInSurah'] as int;
      final key = _getAyahKey(widget.surahNum, ayahNum);
      if (!_completed.containsKey(key)) {
        await widget.onToggleAyah(key, true);
        _completed[key] = true;
      }
    }
    if (_ayahs.isNotEmpty) widget.onSaveCheckpoint(_ayahs.last['numberInSurah'] as int);
    setState(() {});
  }

  Future<void> _resetSurah() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Surah Progress?'),
        content: Text('Clear completion for all ayahs of ${widget.surah['englishName']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final ayah in _ayahs) {
      final ayahNum = ayah['numberInSurah'] as int;
      final key = _getAyahKey(widget.surahNum, ayahNum);
      if (_completed.containsKey(key)) {
        await widget.onToggleAyah(key, false);
        _completed.remove(key);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ayahs = widget.surah['numberOfAyahs'] as int? ?? 0;
    final scrollPct = ayahs > 0 ? (_lastReadAyah / ayahs).clamp(0.0, 1.0) : 0.0;

    final modeBtn = (IconData icon, String label, TranslationMode m) {
      final active = _mode == m;
      return GestureDetector(
        onTap: () => setState(() => _mode = m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: active ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    };

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.surah['englishName'] as String? ?? '',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(widget.surah['name'] as String? ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'Alegreya', color: Theme.of(context).colorScheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${widget.surah['numberOfAyahs']} v',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: scrollPct, minHeight: 3,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(scrollPct >= 1 ? Colors.green : Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('$_lastReadAyah/$ayahs',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  modeBtn(Icons.text_fields, 'Ar', TranslationMode.arabicOnly),
                  const SizedBox(width: 2),
                  modeBtn(Icons.translate, 'Ar+En', TranslationMode.arabicEnglish),
                  const SizedBox(width: 2),
                  modeBtn(Icons.translate, 'Ar+Ur', TranslationMode.arabicUrdu),
                  const SizedBox(width: 2),
                  modeBtn(Icons.language, 'All', TranslationMode.both),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Surah ${widget.surahNum}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text('لَا إِلٰهَ إِلَّا اللهُ مُحَمَّدٌ رَسُولُ اللهِ',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Alegreya'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : PageView.builder(
                      itemCount: _ayahs.length,
                      controller: PageController(initialPage: _lastReadAyah > 0 ? _lastReadAyah - 1 : 0),
                      onPageChanged: (i) async {
                        final ayahNum = _ayahs[i]['numberInSurah'] as int;
                        if (_lastReadAyah != ayahNum) {
                          _lastReadAyah = ayahNum;
                          widget.onSaveCheckpoint(ayahNum);
                          for (final a in _ayahs) {
                            final aNum = a['numberInSurah'] as int;
                            if (aNum <= ayahNum) {
                              final k = _getAyahKey(widget.surahNum, aNum);
                              if (!_completed.containsKey(k)) {
                                _completed[k] = true;
                                await widget.onToggleAyah(k, true);
                              }
                            }
                          }
                          if (mounted) setState(() {});
                        }
                      },
                      itemBuilder: (_, i) {
                        final ayah = _ayahs[i];
                        final ayahNum = ayah['numberInSurah'] as int;
                        final key = _getAyahKey(widget.surahNum, ayahNum);
                        final isCompleted = _completed.containsKey(key);
                        final en = _enTranslations[ayahNum.toString()] ?? '';
                        final ur = _urTranslations[ayahNum.toString()] ?? '';

                        return Container(
                          margin: EdgeInsets.only(left: 6, top: 4, right: i < _ayahs.length - 1 ? 2 : 6, bottom: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(1, 2)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(ayah['text'] as String? ?? '', textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 24, fontFamily: 'Alegreya', height: 1.8,
                                            color: isCompleted ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                                          ),
                                        ),
                                        if (_mode == TranslationMode.arabicEnglish && en.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(en, textAlign: TextAlign.left,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, height: 1.5),
                                            ),
                                          ),
                                        ],
                                        if (_mode == TranslationMode.arabicUrdu && ur.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(ur, textAlign: TextAlign.right,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'Alegreya', height: 1.5),
                                            ),
                                          ),
                                        ],
                                        if (_mode == TranslationMode.both) ...[
                                          if (ur.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(ur, textAlign: TextAlign.right,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'Alegreya', height: 1.5),
                                              ),
                                            ),
                                          ],
                                          if (en.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                                              ),
                                              child: Text(en, textAlign: TextAlign.left,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, height: 1.5),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final newVal = !isCompleted;
                                        await widget.onToggleAyah(key, newVal);
                                        setState(() { if (newVal) _completed[key] = true; else _completed.remove(key); });
                                      },
                                      child: Container(
                                        width: 20, height: 20,
                                        decoration: BoxDecoration(
                                          color: isCompleted ? Colors.green : Colors.transparent,
                                          borderRadius: BorderRadius.circular(4),
                                          border: isCompleted ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.2),
                                        ),
                                        child: isCompleted ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text('${i + 1}',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontFamily: 'Alegreya'),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(':${widget.surahNum}:$ayahNum',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  Text('${_completed.keys.where((k) => k.startsWith('${widget.surahNum}:')).length} completed',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _completeSurah,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Complete',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _resetSurah,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Reset',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Close',
                        style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onPrimary),
                      ),
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
}

class _JuzReaderDialog extends StatefulWidget {
  final int juzNum;
  final Map<String, bool> completedAyats;
  final Future<void> Function(String key, bool completed) onToggleAyah;
  final int initialIndex;
  final void Function(int index) onSaveCheckpoint;
  final void Function(bool complete) onJuzComplete;
  const _JuzReaderDialog({
    required this.juzNum,
    required this.completedAyats,
    required this.onToggleAyah,
    required this.initialIndex,
    required this.onSaveCheckpoint,
    required this.onJuzComplete,
  });

  @override
  State<_JuzReaderDialog> createState() => _JuzReaderDialogState();
}

class _JuzReaderDialogState extends State<_JuzReaderDialog> {
  List<Map<String, dynamic>> _ayahs = [];
  Map<String, String> _enTranslations = {};
  Map<String, String> _urTranslations = {};
  bool _loading = true;
  String _juzName = '';
  int _totalAyahs = 0;
  int _currentIndex = 0;
  late Map<String, bool> _completed;

  @override
  void initState() {
    super.initState();
    _juzName = widget.juzNum <= 30 ? AppConstants.juzNames[widget.juzNum - 1] : '';
    _completed = Map.from(widget.completedAyats);
    _loadAyahs();
  }

  String _getAyahKey(int surah, int ayah) => '$surah:$ayah';

  Future<void> _loadAyahs() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse('https://api.alquran.cloud/v1/juz/${widget.juzNum}/quran-uthmani')),
        http.get(Uri.parse('https://api.alquran.cloud/v1/juz/${widget.juzNum}/en.sahih')),
        http.get(Uri.parse('https://api.alquran.cloud/v1/juz/${widget.juzNum}/ur.maududi')),
      ]);
      final arabic = json.decode(results[0].body)['data']['ayahs'] as List;
      final english = json.decode(results[1].body)['data']['ayahs'] as List;
      final urdu = json.decode(results[2].body)['data']['ayahs'] as List;
      _ayahs = List<Map<String, dynamic>>.from(arabic);
      _totalAyahs = _ayahs.length;
      for (final e in english) {
        _enTranslations['${e['surah']['number']}:${e['numberInSurah']}'] = e['text'] as String;
      }
      for (final u in urdu) {
        _urTranslations['${u['surah']['number']}:${u['numberInSurah']}'] = u['text'] as String;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _completeJuz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Complete?'),
        content: Text('Mark all ${_ayahs.length} ayahs of Para ${widget.juzNum} as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final ayah in _ayahs) {
      final key = _getAyahKey(ayah['surah']['number'] as int, ayah['numberInSurah'] as int);
      if (!_completed.containsKey(key)) {
        await widget.onToggleAyah(key, true);
        _completed[key] = true;
      }
    }
    widget.onJuzComplete(true);
    setState(() {});
  }

  Future<void> _resetJuz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Para Progress?'),
        content: Text('Clear completion for all ayahs of Para ${widget.juzNum}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final ayah in _ayahs) {
      final key = _getAyahKey(ayah['surah']['number'] as int, ayah['numberInSurah'] as int);
      if (_completed.containsKey(key)) {
        await widget.onToggleAyah(key, false);
        _completed.remove(key);
      }
    }
    widget.onJuzComplete(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Para ${widget.juzNum}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(_juzName,
                          style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Alegreya', color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  if (_totalAyahs > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$_totalAyahs v',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
            if (_totalAyahs > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _totalAyahs,
                          minHeight: 3,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${_currentIndex + 1}/$_totalAyahs',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: _loading
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text('لَا إِلٰهَ إِلَّا اللهُ مُحَمَّدٌ رَسُولُ اللهِ',
                          style: theme.textTheme.headlineSmall?.copyWith(fontFamily: 'Alegreya'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : PageView.builder(
                      itemCount: _ayahs.length,
                      controller: PageController(
                        initialPage: widget.initialIndex.clamp(0, _ayahs.length - 1),
                      ),
                      onPageChanged: (i) async {
                        setState(() => _currentIndex = i);
                        widget.onSaveCheckpoint(i);
                        for (var x = 0; x <= i; x++) {
                          final a = _ayahs[x];
                          final k = _getAyahKey(a['surah']['number'] as int, a['numberInSurah'] as int);
                          if (!_completed.containsKey(k)) {
                            _completed[k] = true;
                            await widget.onToggleAyah(k, true);
                          }
                        }
                        final allDone = _ayahs.every((a) => _completed.containsKey(_getAyahKey(a['surah']['number'] as int, a['numberInSurah'] as int)));
                        widget.onJuzComplete(allDone);
                        if (mounted) setState(() {});
                      },
                      itemBuilder: (_, i) {
                        final ayah = _ayahs[i];
                        final surahNum = ayah['surah']['number'] as int;
                        final ayahNum = ayah['numberInSurah'] as int;
                        final key = '$surahNum:$ayahNum';
                        final en = _enTranslations[key] ?? '';
                        final ur = _urTranslations[key] ?? '';
                        final surahName = ayah['surah']['englishName'] as String? ?? '';

                        return Container(
                          margin: EdgeInsets.only(left: 6, top: 4, right: i < _ayahs.length - 1 ? 2 : 6, bottom: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(1, 2)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text('$surahName — Ayah $ayahNum',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.secondary, fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(ayah['text'] as String? ?? '', textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 24, fontFamily: 'Alegreya', height: 1.8,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        if (ur.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(ur, textAlign: TextAlign.right,
                                              style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Alegreya', height: 1.5),
                                            ),
                                          ),
                                        ],
                                        if (en.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                                            ),
                                            child: Text(en, textAlign: TextAlign.left,
                                              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, height: 1.5),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final k = _getAyahKey(surahNum, ayahNum);
                                        final newVal = !_completed.containsKey(k);
                                        await widget.onToggleAyah(k, newVal);
                                        setState(() { if (newVal) _completed[k] = true; else _completed.remove(k); });
                                        final allDone = _ayahs.every((a) => _completed.containsKey(_getAyahKey(a['surah']['number'] as int, a['numberInSurah'] as int)));
                                        widget.onJuzComplete(allDone);
                                      },
                                      child: Container(
                                        width: 20, height: 20,
                                        decoration: BoxDecoration(
                                          color: _completed.containsKey(_getAyahKey(surahNum, ayahNum)) ? Colors.green : Colors.transparent,
                                          borderRadius: BorderRadius.circular(4),
                                          border: _completed.containsKey(_getAyahKey(surahNum, ayahNum)) ? null : Border.all(color: theme.colorScheme.outlineVariant, width: 1.2),
                                        ),
                                        child: _completed.containsKey(_getAyahKey(surahNum, ayahNum)) ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text('${i + 1}/${_ayahs.length}',
                                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Text('${_completed.keys.where((k) => _ayahs.any((a) => _getAyahKey(a['surah']['number'] as int, a['numberInSurah'] as int) == k)).length} completed',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _completeJuz,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Complete',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _resetJuz,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Reset',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Close',
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimary),
                      ),
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
}
