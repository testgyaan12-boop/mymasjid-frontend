import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoorAIPage extends StatefulWidget {
  const NoorAIPage({super.key});

  @override
  State<NoorAIPage> createState() => _NoorAIPageState();
}

class _NoorAIPageState extends State<NoorAIPage> {
  final _queryCtrl = TextEditingController();
  String? _result;
  bool _loading = false;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _loading = true; _result = null; });

    try {
      // TODO: integrate with Genkit backend
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _result = 'This is a placeholder response. The AI assistant will be connected to the Genkit backend.';
        _loading = false;
      });
    } catch (e) {
      setState(() { _result = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Noor AI', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Spiritual Assistant', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              hintText: 'Ask a question...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              suffixIcon: IconButton(
                icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                onPressed: _loading ? null : _ask,
              ),
            ),
            onFieldSubmitted: (_) => _ask(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              'What is the significance of Ramadan?',
              'Tell me about Surah Al-Fatiha',
              'What are the five pillars?',
            ].map((chip) => ActionChip(
              label: Text(chip, style: Theme.of(context).textTheme.bodySmall),
              onPressed: () { _queryCtrl.text = chip; _ask(); },
            )).toList(),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_result!, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
