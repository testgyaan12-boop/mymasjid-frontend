import 'package:flutter/material.dart';
import '../widgets/cards/tasbih_counter.dart';

class TasbihPage extends StatelessWidget {
  const TasbihPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: TasbihCounter()),
    );
  }
}
