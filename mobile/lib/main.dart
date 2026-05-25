import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'providers/word_provider.dart';
import 'providers/progress_provider.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Generate or retrieve a persistent anonymous user ID
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('user_id') ?? '';
  if (userId.isEmpty) {
    userId = const Uuid().v4();
    await prefs.setString('user_id', userId);
  }
  ApiService().setUserId(userId);

  runApp(const EnglishLearningApp());
}

class EnglishLearningApp extends StatelessWidget {
  const EnglishLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        title: 'WordWise',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        // App always starts at the Splash screen.
        // SplashScreen auto-navigates → LoginScreen or HomeScreen
        // based on the saved 'is_logged_in' preference.
        home: const SplashScreen(),
      ),
    );
  }
}
