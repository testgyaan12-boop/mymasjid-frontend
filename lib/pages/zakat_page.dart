import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/masjid_provider.dart';
import '../config/constants.dart';

class ZakatPage extends StatefulWidget {
  const ZakatPage({super.key});

  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends State<ZakatPage> {
  final _goldCtrl = TextEditingController();
  final _silverCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _liabilitiesCtrl = TextEditingController();
  int _familyMembers = 1;

  @override
  void dispose() {
    _goldCtrl.dispose();
    _silverCtrl.dispose();
    _cashCtrl.dispose();
    _businessCtrl.dispose();
    _liabilitiesCtrl.dispose();
    super.dispose();
  }

  double get _totalWealth =>
      (_goldCtrl.asDouble + _silverCtrl.asDouble + _cashCtrl.asDouble + _businessCtrl.asDouble) -
      _liabilitiesCtrl.asDouble;

  bool get _isEligible => _totalWealth >= AppConstants.nisabGoldInr;
  double get _zakatAmount => _isEligible ? _totalWealth * 0.025 : 0;

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final ramadan = cms['ramadan'] as Map<String, dynamic>?;
    final fitraRate = double.tryParse(ramadan?['fitraRate']?.toString() ?? '') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purify Your Wealth', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Calculators for Zakat & Charity', style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          )),
          const SizedBox(height: 20),

          // Zakat al-Mal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text('Zakat al-Mal (Wealth)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInput('Gold Value', Icons.monetization_on, _goldCtrl, Colors.amber),
                  const SizedBox(height: 12),
                  _buildInput('Silver Value', Icons.monetization_on, _silverCtrl, Colors.grey),
                  const SizedBox(height: 12),
                  _buildInput('Cash & Savings', Icons.account_balance, _cashCtrl, Colors.blue),
                  const SizedBox(height: 12),
                  _buildInput('Business Inventory', Icons.business, _businessCtrl, Colors.green),
                  const Divider(height: 24),
                  _buildInput('Short-term Debts', Icons.receipt, _liabilitiesCtrl, Colors.red),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Fitra & Sadaqah
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Zakat al-Fitr (Fitra)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () => setState(() => _familyMembers = (_familyMembers - 1).clamp(1, 100)),
                            ),
                            Text('$_familyMembers', style: Theme.of(context).textTheme.displayMedium),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () => setState(() => _familyMembers = (_familyMembers + 1).clamp(1, 100)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Total: Rs ${(_familyMembers * fitraRate).toInt()}', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w900,
                        )),
                        Text('@ Rs $fitraRate/person', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary, size: 32),
                        const SizedBox(height: 8),
                        Text('General Sadaqah', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          '"Charity wipes out sins just as water extinguishes fire."',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.push('/donations'),
                            child: const Text('Fulfill Charity'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Result card
          Card(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Calculation Result', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Text('Total Net Wealth', style: Theme.of(context).textTheme.bodySmall),
                  Text('Rs ${_totalWealth.toInt().toString()}', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (_totalWealth / AppConstants.nisabGoldInr).clamp(0, 1),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 8),
                  Text('Nisab: Rs ${AppConstants.nisabGoldInr}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isEligible ? Colors.green.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isEligible ? 'Zakat Obligatory' : 'Below Nisab',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _isEligible ? Colors.green : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('Estimated Zakat (2.5%)', style: Theme.of(context).textTheme.bodySmall),
                        Text('Rs ${_zakatAmount.toInt().toString()}', style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w900,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Fitra:', style: Theme.of(context).textTheme.bodySmall),
                      Text('Rs ${(_familyMembers * fitraRate).toInt()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/donations'),
                      icon: const Icon(Icons.favorite),
                      label: const Text('Pay via Masjid', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildInput(String label, IconData icon, TextEditingController ctrl, Color color) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
    );
  }
}

extension _DoubleParse on TextEditingController {
  double get asDouble => double.tryParse(text) ?? 0;
}
