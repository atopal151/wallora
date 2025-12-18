import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/admob_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AdMob'u initialize et (hata durumunda uygulama çalışmaya devam eder)
  try {
    await AdMobService.instance.initialize();
  } catch (e) {
    debugPrint('AdMob initialization error: $e');
    // Uygulama çalışmaya devam eder, sadece reklamlar gösterilmez
  }
  
  runApp(const WalloraApp());
}

class WalloraApp extends StatefulWidget {
  const WalloraApp({super.key});

  @override
  State<WalloraApp> createState() => _WalloraAppState();
}

class _WalloraAppState extends State<WalloraApp> {
  final SettingsService _settingsService = SettingsService();
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final darkMode = await _settingsService.getDarkMode();
    setState(() {
      _darkMode = darkMode;
    });
  }

  void _onThemeChanged() {
    _loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFfafafa),
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onThemeChanged: _onThemeChanged),
    );
  }
}
