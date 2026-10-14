import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';

class AppRoutes {

  final GoRouter appRouter = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell){
            return HomeScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search_engine',
                  builder: (context, state) => const HomeScreen(), //Pendiente de implementar el buscador
                ),
              ]
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/vault',
                  builder: (context, state) => const HomeScreen(), //Pendiente de implementar el armario
                ),
                ]
              ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                 path: '/profile',
                  builder: (context, state) => const HomeScreen(), //Pendiente de implementar el perfil
                )
              ]
            )
          ]
      ),
    ],

  );
}