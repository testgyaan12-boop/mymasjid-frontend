import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../providers/masjid_provider.dart';
import '../config/constants.dart';

class DonationsPage extends StatelessWidget {
  const DonationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final monthly = (cms['monthlyDonations'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final expenses = (cms['expenses'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final causes = (cms['donationCauses'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gifts of Grace', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Support Your Community', style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 20),

          // Monthly collections accordion
          Card(
            child: ExpansionTile(
              title: const Text('Jumu\'ah Collection', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${monthly.length} records', style: Theme.of(context).textTheme.bodySmall),
              children: monthly.map((m) => ListTile(
                title: Text(m['month'] as String? ?? ''),
                trailing: Text('Rs ${m['amount'] as String? ?? '0'}', style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: m['status'] == 'Received' ? Colors.green : Theme.of(context).colorScheme.secondary,
                )),
              )).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Expenses accordion
          Card(
            child: ExpansionTile(
              title: const Text('Transparency & Expenses', style: TextStyle(fontWeight: FontWeight.w700)),
              children: expenses.map((e) => ListTile(
                title: Text(e['label'] as String? ?? ''),
                trailing: Text('Rs ${e['value'] as String? ?? '0'}/mo', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              )).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Donation causes
          ...(causes.isNotEmpty ? causes.map((c) => _buildCauseCard(context, c)) : AppConstants.defaultCauses.map((c) => _buildCauseCard(context, c))),

          const SizedBox(height: 20),

          // Hadith quote
          Card(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '"The believer\'s shade on the Day of Resurrection will be his charity." — Prophet Muhammad (PBUH)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCauseCard(BuildContext context, Map<String, dynamic> cause) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cause['badge'] as String? ?? 'Sadaqah', style: Theme.of(context).textTheme.labelSmall),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(cause['title'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(cause['description'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'UPI: ${cause['upi'] as String? ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cause['upi'] as String? ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI copied!')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    onPressed: () => Share.share('Support ${cause['title']}: ${cause['upi']}'),
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
