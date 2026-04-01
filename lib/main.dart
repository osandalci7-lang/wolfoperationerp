import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const WolfOperationApp(),
    ),
  );
}

class WolfOperationApp extends StatelessWidget {
  const WolfOperationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final isLoginPage = state.matchedLocation == '/login';
        if (!isLoggedIn && !isLoginPage) return '/login';
        if (isLoggedIn && isLoginPage) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
            path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'WolfOperation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a73e8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: router,
    );
  }
}
