import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

// Global navigator key untuk akses navigation dari mana saja
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
    debugPrint('Using default API configuration');
  }
  
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
        navigatorKey: navigatorKey, // Set global navigator key
        home: const SplashScreen(),
      ),
    );
  }
}

// Function untuk handle unauthorized dari API service
void handleSessionExpired() {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  
  // Clear providers
  context.read<AuthProvider>().logout();
  context.read<HomeProvider>().stopAutoRefresh();
  
  // Show message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Session telah berakhir. Silakan login kembali.'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    ),
  );
  
  // Navigate to login dan hapus semua route sebelumnya
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}