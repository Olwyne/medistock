import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/family_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/family_choice_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      EnvConfig.setFromDotenv(url, key);
    } catch (_) {
      // .env manquant ou clés vides : mode local sans Supabase
    }
  }

  if (EnvConfig.isConfigured) {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  }

  await ReminderService.init();
  runApp(const MediStockApp());
}

class MediStockApp extends StatelessWidget {
  const MediStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => MedicationProvider(auth: context.read<AuthProvider>())..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (context) => FamilyProvider(auth: context.read<AuthProvider>())..load()),
        ChangeNotifierProvider(create: (context) => ShoppingProvider(auth: context.read<AuthProvider>())..load()),
      ],
      child: Consumer4<AuthProvider, ThemeProvider, LocaleProvider, SettingsProvider>(
        builder: (context, authProvider, themeProvider, localeProvider, settingsProvider, _) {
          Widget home;
          if (!authProvider.isConfigured) {
            home = settingsProvider.onboardingDone
                ? const HomeScreen()
                : const OnboardingScreen();
          } else if (!authProvider.isSignedIn) {
            home = const LoginScreen();
          } else if (!authProvider.hasFamily) {
            home = const FamilyChoiceScreen();
          } else if (!settingsProvider.onboardingDone) {
            home = const OnboardingScreen();
          } else {
            home = const HomeScreen();
          }

          return MaterialApp(
            title: 'MediStock',
            debugShowCheckedModeBanner: false,
            supportedLocales: const [Locale('fr'), Locale('en')],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            locale: localeProvider.locale,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: Brightness.light),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: Brightness.dark),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: home,
          );
        },
      ),
    );
  }
}
