import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:followup/screens/auth/login_screen.dart';
import 'package:followup/providers/language_provider.dart';
import 'package:followup/providers/auth_provider.dart';
import 'package:followup/models/user_model.dart';
import 'package:followup/screens/admin/admin_dashboard_screen.dart';
import 'package:followup/services/auth_service.dart';
import 'firebase_options.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/sheikh/sheikh_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize admin user
  await AuthService().initializeAdmin();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ThemeData.light();
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Student Follow-up',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale,
      home: const RootRouter(),
      // Add named routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/sheikh/dashboard': (context) => const SheikhDashboard(),
        '/parent/dashboard': (context) => const ParentDashboard(),
        // Add other routes here
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes or show error page
        return MaterialPageRoute(
          builder: (context) =>
              Scaffold(body: Center(child: Text('No route defined for ${settings.name}'))),
        );
      },
    );
  }
}

class RootRouter extends ConsumerWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // Navigate based on user role
        WidgetsBinding.instance.addPostFrameCallback((_) {
          switch (user.role) {
            case UserRole.admin:
              Navigator.of(context).pushNamedAndRemoveUntil('/admin/dashboard', (route) => false);
              break;
            case UserRole.sheikh:
              Navigator.of(context).pushNamedAndRemoveUntil('/sheikh/dashboard', (route) => false);
              break;
            case UserRole.parent:
              Navigator.of(context).pushNamedAndRemoveUntil('/parent/dashboard', (route) => false);
              break;
          }
        });

        // Show loading while navigating
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
