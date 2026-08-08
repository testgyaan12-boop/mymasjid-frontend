import 'package:dio/dio.dart';

class RamadanDate {
  final int hijriYear;
  final bool isRamadan;
  final int? ramadanDay;
  final int daysUntilRamadan;

  const RamadanDate({
    required this.hijriYear,
    required this.isRamadan,
    this.ramadanDay,
    required this.daysUntilRamadan,
  });
}

class RamadanService {
  static const _hijriMonths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];
  static const _leapYears = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};

  static bool _isLeap(int y) {
    final cy = y % 30;
    return _leapYears.contains(cy == 0 ? 30 : cy);
  }

  static List<int> _toHijri(DateTime date) {
    final epoch = DateTime(622, 7, 19);
    int days = date.difference(epoch).inDays;
    if (days < 0) return [1, 1, 1447];
    const cycleDays = 10631;
    int cycles = days ~/ cycleDays;
    days %= cycleDays;
    int year = cycles * 30 + 1;
    for (int y = 1; y <= 30; y++) {
      final yDays = _isLeap(y) ? 355 : 354;
      if (days < yDays) break;
      days -= yDays;
      year++;
    }
    int month = 1;
    for (int m = 0; m < 12; m++) {
      var md = _hijriMonths[m];
      if (m == 11 && _isLeap(year)) md = 30;
      if (days < md) break;
      days -= md;
      if (month < 12) month++;
    }
    return [month, days + 1, year];
  }

  static const _monthCumStart = [0, 30, 59, 89, 118, 148, 177, 207, 236, 266, 295, 325];
  static const _ramadanStartCum = 236;

  static RamadanDate _compute(DateTime now, int hijriMonth, int hijriDay, int hijriYear) {
    int yearDays = _isLeap(hijriYear) ? 355 : 354;
    final elapsed = _monthCumStart[hijriMonth - 1] + (hijriDay - 1);
    if (hijriMonth == 9) {
      return RamadanDate(
        hijriYear: hijriYear,
        isRamadan: true,
        ramadanDay: hijriDay,
        daysUntilRamadan: 0,
      );
    }
    int daysUntil = _ramadanStartCum - elapsed;
    if (hijriMonth > 9) daysUntil += yearDays;
    return RamadanDate(
      hijriYear: hijriYear,
      isRamadan: false,
      daysUntilRamadan: daysUntil < 0 ? 0 : daysUntil,
    );
  }

  static Future<RamadanDate> today() async {
    final now = DateTime.now();
    final local = _toHijri(now);
    try {
      final d = now.day.toString().padLeft(2, '0');
      final m = now.month.toString().padLeft(2, '0');
      final y = now.year.toString();
      final res = await Dio().get<Map<String, dynamic>>(
        'https://api.aladhan.com/v1/gToH?date=$d-$m-$y',
      ).timeout(const Duration(seconds: 4));
      final data = res.data?['data'] as Map<String, dynamic>?;
      final hijri = data?['hijri'] as Map<String, dynamic>?;
      final month = (hijri?['month'] as Map<String, dynamic>?)?['number'] as int?;
      final day = int.tryParse(hijri?['day']?.toString() ?? '');
      final yearNum = int.tryParse(hijri?['year']?.toString() ?? '');
      if (month != null && day != null && yearNum != null) {
        return _compute(now, month, day, yearNum);
      }
    } catch (_) {}
    return _compute(now, local[0], local[1], local[2]);
  }
}