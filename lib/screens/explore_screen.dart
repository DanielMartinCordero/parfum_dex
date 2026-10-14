import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Symbols.search, size: 80, color: Colors.deepPurple),
          SizedBox(height: 24),
          Text(
            'Pantalla Explorar / Catálogo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'El estado se mantendrá aquí.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
