import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/masjid_provider.dart';
import '../config/constants.dart';

class DonationsPage extends StatelessWidget {
  const DonationsPage({super.key});

  String _numStr(dynamic v) {
    if (v == null) return '0';
    if (v is num) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toString();
    }
    return v.toString();
  }

  String _dateLabel(dynamic d) {
    if (d == null) return '';
    return d.toString();
  }

  Widget _qrImage(BuildContext context, String qr, double size) {
    final isUrl = qr.startsWith('http');
    final Widget img = isUrl
        ? Image.network(qr, width: size, height: size, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 80))
        : Image.memory(base64Decode(qr), width: size, height: size, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 80));
    return Container(
      color: isUrl ? null : Colors.white,
      child: img,
    );
  }

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final monthly = (cms['monthlyDonations'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    // final expenses = (cms['expenses'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
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
          const SizedBox(height: 8),

          // Monthly collections accordion
          Card(
            child: ExpansionTile(
              title: const Text('Collections', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${monthly.length} records', style: Theme.of(context).textTheme.bodySmall),
              children: monthly.map((m) => ListTile(
                title: Text(_dateLabel(m['donationDate'])),
                trailing: Text('Rs ${_numStr(m['amount'])}', style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: m['status'] == 'Received' ? Colors.green : Theme.of(context).colorScheme.secondary,
                )),
              )).toList(),
            ),
          ),

          const SizedBox(height: 4),

          /* Commented out - Transparency & Expenses section
          // Expenses accordion
          Card(
            child: ExpansionTile(
              title: const Text('Transparency & Expenses', style: TextStyle(fontWeight: FontWeight.w700)),
              children: expenses.map((e) => ListTile(
                title: Text(e['label'] as String? ?? ''),
                trailing: Text('Rs ${_numStr(e['value'])}/mo', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              )).toList(),
            ),
          ),
          */

          const SizedBox(height: 4),

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
    final key = GlobalKey();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          RepaintBoundary(
            key: key,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GestureDetector(
                          onTap: () => _shareCauseCard(context, key, cause),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.ios_share, size: 14, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('Share', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700,
                              )),
                            ],
                          ),
                        ),
                      ),
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
                          onPressed: () => _shareCauseText(context, cause),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if ((cause['qrImage'] as String?)?.isNotEmpty == true)
                    InkWell(
                      onTap: () => _showQrDialog(context, cause),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _qrImage(context, cause['qrImage'] as String, 180),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.tap_and_play, size: 14, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap QR to scan',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCauseText(BuildContext context, Map<String, dynamic> cause) async {
    await Share.share(
      '${cause['badge'] as String? ?? 'Sadaqah'} • ${cause['title'] as String? ?? ''}\n\n'
      '${cause['description'] as String? ?? ''}\n\n'
      'UPI: ${cause['upi'] as String? ?? ''}',
      subject: 'Support ${cause['title'] as String? ?? ''}',
    );
  }

  Future<void> _shareCauseCard(BuildContext context, GlobalKey key, Map<String, dynamic> cause) async {
    try {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null || !context.mounted) return;
      final temp = await getTemporaryDirectory();
      final file = File('${temp.path}/donation_card.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${cause['badge'] as String? ?? 'Sadaqah'} • ${cause['title'] as String? ?? ''}\n'
              'UPI: ${cause['upi'] as String? ?? ''}',
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not share card')));
    }
  }

  void _showQrDialog(BuildContext context, Map<String, dynamic> cause) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: _qrImage(context, cause['qrImage'] as String, 280),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              cause['title'] as String? ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'UPI: ${cause['upi'] as String? ?? ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
