import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  //Encargado de controlar las pantallas principales del BottomNavigationBar
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ParfumDex"), centerTitle: true),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const[
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Catálogo'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Armario'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil')
        ],
      ),
    );
  }

  }