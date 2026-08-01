import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/masjid_provider.dart';

class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const _hijriMonths = {
    1: 'Muharram', 2: 'Safar', 3: "Rabi' al-Awwal", 4: "Rabi' al-Thani",
    5: 'Jumada al-Awwal', 6: 'Jumada al-Thani', 7: 'Rajab', 8: "Sha'ban",
    9: 'Ramadan', 10: 'Shawwal', 11: "Dhul-Qi'dah", 12: 'Dhul-Hijjah',
  };

  static const _leapYears = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};

  bool _isLeapInCycle(int y) => _leapYears.contains(y);

  String _toHijri(DateTime date) {
    final epoch = DateTime(622, 7, 19);
    int days = date.difference(epoch).inDays;
    if (days < 0) return '';
    const cycleDays = 10631;
    int cycles = days ~/ cycleDays;
    days %= cycleDays;
    int year = cycles * 30 + 1;
    for (int y = 1; y <= 30; y++) {
      final yDays = _isLeapInCycle(y) ? 355 : 354;
      if (days < yDays) break;
      days -= yDays;
      year++;
    }
    const mDays = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
    int month = 1;
    for (int m = 0; m < 12; m++) {
      var md = mDays[m];
      if (m == 11 && _isLeapInCycle(year % 30 == 0 ? 30 : year % 30)) md = 30;
      if (days < md) break;
      days -= md;
      if (month < 12) month++; else break;
    }
    final monthName = _hijriMonths[month] ?? '';
    return '${days + 1} $monthName $year AH';
  }

  String _prayerNameIcon(String name) {
    switch (name) {
      case 'Fajr': return '🌅';
      case 'Dhuhr': return '☀️';
      case 'Asr': return '⛅';
      case 'Maghrib': return '🌇';
      case 'Isha': return '🌙';
      default: return '⏰';
    }
  }

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final savedTimes = (cms['prayerTimes'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final jumuah = cms['jumuah'] as Map<String, dynamic>?;

    savedTimes.sort((a, b) => ((a['sortOrder'] as int?) ?? 99).compareTo((b['sortOrder'] as int?) ?? 99));

    final nowMinutes = _now.hour * 60 + _now.minute;
    Map<String, dynamic>? next;
    int? smallestDiff;
    for (final p in savedTimes) {
      int pMin = 0;
      final timeStr = (p['azaan'] as String?) ?? '';
      if (timeStr.isNotEmpty) {
        try {
          final parts = timeStr.split(RegExp(r'[\s:]'));
          if (parts.length >= 2) {
            int h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            if (parts.length >= 3 && parts[2].toUpperCase() == 'PM' && h != 12) h += 12;
            if (parts.length >= 3 && parts[2].toUpperCase() == 'AM' && h == 12) h = 0;
            pMin = h * 60 + m;
          }
        } catch (_) {}
      }
      if (pMin > nowMinutes) {
        final diff = pMin - nowMinutes;
        if (smallestDiff == null || diff < smallestDiff) {
          smallestDiff = diff;
          next = p;
        }
      }
    }
    final nextPrayer = next ?? (savedTimes.isNotEmpty ? savedTimes.first : null);

    final isFriday = _now.weekday == DateTime.friday;
    final gregorian = DateFormat('EEEE, MMMM d, yyyy').format(_now);
    final hijri = _toHijri(_now);
    final formattedTime = DateFormat('hh:mm:ss a').format(_now);

    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Text(formattedTime, style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                )),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(gregorian, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(hijri, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),

          if (nextPrayer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Upcoming: ${nextPrayer['name']}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text('Azaan', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(nextPrayer['azaan'] as String? ?? '', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 32)),
                      Column(
                        children: [
                          Text('Iqamah', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                          const SizedBox(height: 4),
                          Text(nextPrayer['time'] as String? ?? '', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          )),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Add prayer times in Admin to see them here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ),

          if (jumuah != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isFriday ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08) : null,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumu\'ah Prayer', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        Text('Weekly Congregation', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Iqamah Time', style: Theme.of(context).textTheme.bodySmall),
                      Text(jumuah['time'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.secondary,
                      )),
                    ],
                  ),
                ],
              ),
            ),

          if (savedTimes.length >= 5)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              childAspectRatio: 0.8,
              children: savedTimes.take(5).map((p) {
                final isNext = p['name'] == nextPrayer?['name'];
                return Container(
                  decoration: BoxDecoration(
                    color: isNext ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1) : null,
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_prayerNameIcon(p['name'] as String? ?? ''), style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(p['name'] as String? ?? '', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
                      Text('A: ${(p['azaan'] as String?)?.split(' ').first ?? ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
                      Text('I: ${(p['time'] as String?)?.split(' ').first ?? ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
