import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/more_screen.dart';
import 'screens/add_edit_transaction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make system navigation bar transparent/themed
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final storageService = await StorageService.init();
  final appState = AppState(storageService);
  await appState.initialize();

  runApp(ExpenseTrackerApp(appState: appState));
}

class ExpenseTrackerApp extends StatelessWidget {
  final AppState appState;

  const ExpenseTrackerApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: appState,
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: appState.themeMode,
            theme: AppTheme.buildLightTheme(appState.accentSeedColor),
            darkTheme: AppTheme.buildDarkTheme(appState.accentSeedColor),
            home: const AppRootGate(),
          );
        },
      ),
    );
  }
}

class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    // 1. If not onboarded, show Onboarding Flow
    if (!appState.hasOnboarded) {
      return const OnboardingScreen();
    }

    // 2. If app is locked, show PIN Lock Screen
    if (appState.isLocked) {
      return const LockScreen();
    }

    // 3. Otherwise show Main App Navigation
    return const MainNavigationScaffold();
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    StatsScreen(),
    MoreScreen(),
  ];

  void _onAddTransaction() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddEditTransactionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTransaction,
        elevation: 4,
        tooltip: 'Add Transaction',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
