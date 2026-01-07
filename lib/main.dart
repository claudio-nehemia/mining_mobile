import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
    debugPrint('Using default API configuration');
  }
  
  // Request location permission on app start
  await _requestLocationPermission();
  
  runApp(const MyApp());
}

Future<void> _requestLocationPermission() async {
  try {
    final status = await Permission.location.request();
    if (status.isGranted) {
      debugPrint('✅ Location permission granted');
    } else if (status.isDenied) {
      debugPrint('⚠️ Location permission denied');
    } else if (status.isPermanentlyDenied) {
      debugPrint('❌ Location permission permanently denied');
    }
  } catch (e) {
    debugPrint('❌ Error requesting location permission: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        title: 'Driver App',
        theme: ThemeConfig.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}