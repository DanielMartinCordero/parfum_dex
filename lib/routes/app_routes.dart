import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:parfum_dex/screens/explore_screen.dart';

import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_shell.dart';
import '../screens/vault_screen.dart';
import '../screens/perfume_detail_screen.dart';
import '../models/perfume.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String explore = '/explore';
  static const String vault = '/vault';
  static const String profile = '/profile';

  static final GoRouter appRouter = GoRouter(
    initialLocation: splash,
    // 2. GUARDIA DE NAVEGACIÓN GLOBAL (Route Guard)
    redirect: (context, state) {
      // Comprobamos si hay sesión activa en Firebase en este instante
      final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

      // Obtenemos la ruta exacta a la que intenta acceder el usuario
      final String location = state.matchedLocation;
      List<String> publicRoutes = [splash, onboarding, login, register];
      // Definimos cuáles son las rutas públicas (a las que se puede entrar sin cuenta)
      final bool isPublicRoute = publicRoutes.contains(location);

      // CASO A: NO está logueado e intenta entrar a una ruta privada (/explore, /vault, /profile)
      if (!isLoggedIn && !isPublicRoute) {
        return login; // Bloqueado: lo mandamos directo al Login
      }

      // CASO B: SÍ está logueado pero intenta volver a /login o /register escribiendo la URL
      if (isLoggedIn && (location == login || location == register)) {
        return explore; // Ya tiene sesión: lo mandamos dentro de la app
      }

      // CASO C: Todo correcto, permitimos que continúe a la ruta solicitada
      return null;
    },

    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: explore,
                builder: (context, state) => const ExploreScreen(),
                routes: [
                  GoRoute(
                    // Usamos un parámetro de ruta dinámico: :id
                    path: 'detail/:id',
                    builder: (context, state) {
                      // 1. Extraemos el ID directamente de la URL
                      final String perfumeId = state.pathParameters['id']!;

                      // 2. Extraemos el objeto entero de la memoria (puede ser nulo si pulsan F5)
                      final perfume = state.extra as Perfume?;

                      // Pasamos ambos datos a la pantalla
                      return PerfumeDetailScreen(
                        perfumeId: perfumeId,
                        initialPerfume: perfume,
                      );
                    },
                  ),
                ],
              ),
            ]
          ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                 path: profile,
                  builder: (context, state) => const ProfileScreen(), //Pendiente de implementar el perfil
                )
              ]
            )
          ]
      ),
    ],
  );
}