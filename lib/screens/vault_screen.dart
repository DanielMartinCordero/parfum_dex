import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ParfumDex")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Symbols.inventory_2, size: 80, color: Colors.deepPurple),
            SizedBox(height: 24),
            Text(
              'Tu Bóveda Personal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
