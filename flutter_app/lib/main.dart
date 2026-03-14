import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/send_screen.dart';
import 'screens/history_screen.dart';
import 'screens/batches_screen.dart';

void main() {
  runApp(const ZKWalletApp());
}

class ZKWalletApp extends StatefulWidget {
  const ZKWalletApp({super.key});

  @override
  State<ZKWalletApp> createState() => _ZKWalletAppState();
}

class _ZKWalletAppState extends State<ZKWalletApp> {
  final ApiService apiService = ApiService();

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => DashboardScreen(apiService: apiService)),
      GoRoute(path: '/send', builder: (context, state) => SendScreen(apiService: apiService)),
      GoRoute(path: '/history', builder: (context, state) => HistoryScreen(apiService: apiService)),
      GoRoute(path: '/batches', builder: (context, state) => BatchesScreen(apiService: apiService)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZK Rollup Wallet',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent), useMaterial3: true),
      routerConfig: _router,
    );
  }
}

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('ZK Wallet'),
      actions: [
        TextButton(onPressed: () => context.go('/'), child: const Text('Dashboard', style: TextStyle(color: Colors.white))),
        TextButton(onPressed: () => context.go('/send'), child: const Text('Send', style: TextStyle(color: Colors.white))),
        TextButton(onPressed: () => context.go('/history'), child: const Text('History', style: TextStyle(color: Colors.white))),
        TextButton(onPressed: () => context.go('/batches'), child: const Text('Batches', style: TextStyle(color: Colors.white))),
      ],
      backgroundColor: Theme.of(context).colorScheme.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}