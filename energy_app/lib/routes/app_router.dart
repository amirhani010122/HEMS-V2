import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/logic/auth_provider.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/register_page.dart';
import '../../features/dashboard/ui/dashboard_page.dart';
import '../../features/devices/ui/devices_page.dart';
import '../../features/devices/ui/device_detail_page.dart';
import '../../features/consumption/ui/consumption_page.dart';
import '../../features/plans/ui/plans_page.dart';
import '../../features/alerts/ui/alerts_page.dart';
import '../../features/ai/ui/ai_insights_page.dart';
import '../../features/profile/ui/profile_page.dart';
import '../../shared/widgets/app_drawer.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState is AuthAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isAuth = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main app routes with drawer
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const _ScaffoldWithDrawer(
          child: DashboardPage(),
        ),
      ),
      GoRoute(
        path: '/devices',
        builder: (context, state) => const _ScaffoldWithDrawer(
          child: DevicesPage(),
        ),
      ),
      GoRoute(
        path: '/devices/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _ScaffoldWithDrawer(
            child: DeviceDetailPage(deviceId: id),
          );
        },
      ),
      GoRoute(
        path: '/consumption',
        builder: (context, state) => const _ScaffoldWithDrawer(
          child: ConsumptionPage(),
        ),
      ),
      GoRoute(
        path: '/plans',
        builder: (context, state) => const _ScaffoldWithDrawer(
          child: PlansPage(),
        ),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const _ScaffoldWithDrawer(
          child: AlertsPage(),
        ),
      ),
      GoRoute(
        path: '/ai-insights',
        builder: (context, state) => const _ScaffoldWithDrawer(
          child: AiInsightsPage(),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const _ScaffoldWithDrawer(
          child: ProfilePage(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

class _ScaffoldWithDrawer extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithDrawer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
    );
  }
}
