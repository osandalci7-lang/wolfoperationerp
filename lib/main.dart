import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employees/employees_screen.dart';
import 'screens/safety/safety_screen.dart';
import 'screens/ncr/ncr_screen.dart';
import 'screens/vendors/vendors_screen.dart';
import 'screens/planning/planning_screen.dart';
import 'screens/certificates/certificates_screen.dart';
import 'screens/financial/financial_screen.dart';
import 'core/constants.dart';

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
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/employees', builder: (_, __) => const EmployeesScreen()),
        GoRoute(path: '/safety', builder: (_, __) => const SafetyScreen()),
        GoRoute(path: '/ncr', builder: (_, __) => const NcrScreen()),
        GoRoute(path: '/vendors', builder: (_, __) => const VendorsScreen()),
        GoRoute(path: '/planning', builder: (_, __) => const PlanningScreen()),
        GoRoute(path: '/certificates', builder: (_, __) => const CertificatesScreen()),
        GoRoute(path: '/financial', builder: (_, __) => const FinancialScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'WolfOperation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: router,
    );
  }
}
