import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/masjid_provider.dart';
import '../../services/ramadan_service.dart';

class RamadanScheduleCard extends StatefulWidget {
  const RamadanScheduleCard({super.key});

  @override
  State<RamadanScheduleCard> createState() => _RamadanScheduleCardState();
}

class _RamadanScheduleCardState extends State<RamadanScheduleCard> {
  RamadanDate? _ramadan;
  final ScrollController _scheduleScroller = ScrollController();

  static const double _scheduleCardExtent = 118;

  @override
  void initState() {
    super.initState();
    _loadCountdown();
  }

  @override
  void dispose() {
    _scheduleScroller.dispose();
    super.dispose();
  }

  void _centerSchedule(int dayNo) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scheduleScroller.hasClients) return;
      final pos = _scheduleScroller.position;
      final target = (dayNo - 1) * _scheduleCardExtent;
      final centered = target + (_scheduleCardExtent / 2) - (pos.viewportDimension / 2);
      final clamped = centered.clamp(0.0, pos.maxScrollExtent).toDouble();
      _scheduleScroller.animateTo(clamped,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  Future<void> _loadCountdown() async {
    final r = await RamadanService.today();
    if (mounted) {
      setState(() => _ramadan = r);
      // Refresh near midnight to update the day count.
      final now = DateTime.now();
      final untilMidnight = Duration(
        hours: 23 - now.hour,
        minutes: 59 - now.minute,
        seconds: 60 - now.second,
      );
      Future.delayed(untilMidnight, _loadCountdown);
    }
  }

  String? _formatTime(String? v) {
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String get _statusText {
    final current = _ramadan;
    if (current == null) return 'Ramadan';
    if (current.isRamadan) return 'Ramadan - Day ${current.ramadanDay}';
    final remaining = current.daysUntilRamadan + 1;
    return remaining == 1 ? 'Ramadan begins tomorrow' : 'Ramadan begins in $remaining days';
  }

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final ramadan = cms['ramadan'] as Map<String, dynamic>?;
    final days = (cms['ramadanDays'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    if (ramadan == null) return const SizedBox.shrink();

    days.sort((a, b) => ((a['dayNo'] as num?) ?? 0).compareTo((b['dayNo'] as num?) ?? 0));

    final current = _ramadan;
    int? currentDay;
    if (current != null && current.isRamadan && current.ramadanDay != null) {
      currentDay = current.ramadanDay;
    }

    Map<String, dynamic>? todayRow;
    if (currentDay != null && days.isNotEmpty) {
      todayRow = days[currentDay - 1];
    }
    final sehri = _formatTime(todayRow?['sehriEnd'] as String?);
    final iftar = _formatTime(todayRow?['iftarTime'] as String?);

    if (currentDay != null && days.isNotEmpty) {
      _centerSchedule(currentDay);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A237E),
                  const Color(0xFF283593).withValues(alpha: 0.85),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.nights_stay, color: Colors.amber.shade300, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'رمضان كريم',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.nights_stay, color: Colors.amber.shade300, size: 22),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if ((sehri != null || iftar != null) && todayRow != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A237E).withValues(alpha: 0.08),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.restaurant, size: 16, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 6),
                            Text('Today (Ramadan ${todayRow['dayNo']})',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (sehri != null)
                              Expanded(
                                child: _buildInfoRow(context, Icons.wb_twilight, 'Sehri End', sehri),
                              ),
                            if (sehri != null && iftar != null) const SizedBox(width: 8),
                            if (iftar != null)
                              Expanded(
                                child: _buildInfoRow(context, Icons.dinner_dining, 'Iftar', iftar),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (days.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.event_note, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Full Ramadan Schedule',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${days.length} days', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 124,
                    child: ListView.builder(
                      controller: _scheduleScroller,
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      itemExtent: _scheduleCardExtent,
                      itemBuilder: (_, i) {
                        final d = days[i];
                        final isToday = currentDay != null && d['dayNo'] == currentDay;
                        final sehri = _formatTime(d['sehriEnd'] as String?) ?? '-';
                        final iftar = _formatTime(d['iftarTime'] as String?) ?? '-';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isToday
                                  ? LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.72),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isToday
                                  ? null
                                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Day ${d['dayNo'] ?? i + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isToday ? Colors.white : Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                                if (isToday)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('· Today ·',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.wb_twilight, size: 12, color: isToday ? Colors.white70 : Theme.of(context).colorScheme.secondary),
                                    const SizedBox(width: 3),
                                    Text(sehri,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isToday ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.dinner_dining, size: 12, color: isToday ? Colors.white70 : Theme.of(context).colorScheme.tertiary),
                                    const SizedBox(width: 3),
                                    Text(iftar,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isToday ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (ramadan['taraweeh'] != null)
                        _buildInfoRow(context, Icons.nights_stay, 'Taraweeh', ramadan['taraweeh'] as String),
                      if (ramadan['fitraRate'] != null)
                        _buildInfoRow(context, Icons.monetization_on, 'Fitra Rate', 'Rs ${ramadan['fitraRate']}'),
                      if (ramadan['note'] != null && (ramadan['note'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(ramadan['note'] as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.primary,
                                  )),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 5),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}