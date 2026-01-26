import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Services/auth_service.dart';

// Conditional import based on platform
import 'Database/database_init_desktop.dart'
    if (dart.library.html) 'Database/database_init_web.dart';

// IMPORT SEMUA PAGE
import 'Pages/login.dart';
import 'Pages/home.dart';
import 'Pages/category.dart';
import 'Pages/budget.dart';
import 'Pages/transaksi.dart';
import 'Pages/profile.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale
  await initializeDateFormatting('id', null);

  // Initialize database for desktop platforms
  initializeDatabaseForDesktop();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance Tracker',

      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: false,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
          },
        ),
      ),

      // Check session and navigate accordingly
      home: const AuthChecker(),

      // SEMUA ROUTE RESMI
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/kategori': (context) => const CategoryPage(),
        '/budget': (context) => const BudgetPage(),
        '/transaksi': (context) => const TransaksiPage(),
        '/profil': (context) => const ProfilePage(),
      },
    );
  }
}

// Safe Auth Checker to prevent navigation crashes
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!mounted) return;

      // Navigate to proper page and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        isLoggedIn ? '/home' : '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E88E5)),
            SizedBox(height: 20),
            Text(
              'Memulai Finance Tracker...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
