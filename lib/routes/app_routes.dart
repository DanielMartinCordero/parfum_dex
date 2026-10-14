import 'package:go_router/go_router.dart';
import 'package:parfum_dex/screens/explore_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_shell.dart';
import '../screens/vault_screen.dart';

class AppRoutes {

  static final GoRouter appRouter = GoRouter(
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
            return HomeShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/explore',
                  builder: (context, state) => const ExploreScreen(), //Pendiente de implementar el buscador
                ),
              ]
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/vault',
                  builder: (context, state) => const VaultScreen(), //Pendiente de implementar el armario
                ),
                ]
              ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                 path: '/profile',
                  builder: (context, state) => const ProfileScreen(), //Pendiente de implementar el perfil
                )
              ]
            )
          ]
      ),
    ],

  );
}