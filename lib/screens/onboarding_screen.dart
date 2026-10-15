import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parfum_dex/services/preferences_service.dart';

import '../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Finalizar Onboarding: Guarda en preferencias y navega a Login
  void _completeOnboarding() async {
    await PreferencesService.setNotFirstTime();
    if (!mounted) return;
      context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Botón "Saltar" arriba a la derecha
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Saltar'),
              ),
            ),

            // Carrusel de páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  OnboardingPage(
                    icon: Icons.inventory_2,
                    title: 'Bóveda Personal',
                    description: 'Gestiona tu colección de perfumes, controla el líquido restante y calcula el costo por spray.',
                  ),
                  OnboardingPage(
                    icon: Icons.scale,
                    title: 'Calculadora de Tara',
                    description: 'Descubre cuánto líquido real queda en botellas opacas usando nuestra base de datos de pesos.',
                  ),
                  OnboardingPage(
                    icon: Icons.sell,
                    title: 'Agregador de Precios',
                    description: 'Encuentra las mejores ofertas en tiempo real en tiendas como Primor, Druni, Sephora y más.',
                  ),
                ],
              ),
            ),

            // Indicadores (Puntos) y Botones inferiores
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Puntos de progreso
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Botón Siguiente / Empezar
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == 2) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_currentPage == 2 ? 'Empezar' : 'Siguiente'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para cada página del Onboarding
class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}