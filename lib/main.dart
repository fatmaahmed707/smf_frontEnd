import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Screens/announcements/announcements_page.dart';
import 'providers/language_provider.dart';
import 'Screens/profile/profile_page.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'Screens/login/login_page.dart';
import 'Screens/login/register_page.dart';
import 'Screens/dashboard/dashboard_page.dart';
import 'utils/dashboard_history.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSession = await AuthService.instance.restoreSession();
  final languageProvider = await LanguageProvider.create();
  final themeProvider = await ThemeProvider.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: SMFApp(initiallyAuthenticated: hasSession),
    ),
  );
}

class SMFApp extends StatelessWidget {
  final bool initiallyAuthenticated;

  const SMFApp({
    super.key,
    required this.initiallyAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return Directionality(
          textDirection:
              languageProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp(
            title: 'SMF - Security Monitoring',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            initialRoute: DashboardHistory.currentRoute(initiallyAuthenticated),
            onGenerateRoute: _generateRoute,
            builder: (context, child) => Directionality(
              textDirection: languageProvider.isArabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
            routes: {
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/dashboard': (context) => const DashboardPage(),
              '/announcements': (context) => const AnnouncementsPage(),
              '/profile': (context) => const ProfilePage(),
            },
          ),
        );
      },
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final rawName = settings.name ?? '';
    final uri = Uri.tryParse(rawName.startsWith('/') ? rawName : '/$rawName');
    final path = uri?.path.isNotEmpty == true ? uri!.path : '/';

    Widget page;
    switch (path) {
      case '/':
        page = initiallyAuthenticated ? const DashboardPage() : const LoginPage();
        break;
      case '/login':
        page = const LoginPage();
        break;
      case '/register':
        page = const RegisterPage();
        break;
      case '/dashboard':
        page = const DashboardPage();
        break;
      case '/announcements':
        page = const AnnouncementsPage();
        break;
      case '/profile':
        page = const ProfilePage();
        break;
      default:
        page = initiallyAuthenticated ? const DashboardPage() : const LoginPage();
    }

    return MaterialPageRoute(
      settings: RouteSettings(name: path, arguments: settings.arguments),
      builder: (_) => page,
    );
  }
}
