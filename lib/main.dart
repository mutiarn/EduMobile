import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_edu/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/siswa/home_siswa.dart';
import 'screens/pengajar/home_pengajar.dart';
import 'package:mobile_edu/providers/theme_provider.dart';
import 'screens/admin/home_admin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env/.env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ProviderScope(child: MyApp()));
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'MobileEdu',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1f2967),
          secondary: Color(0xFF4a5394),
          background: Color(0xFFF5F5F5),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9fa8ff),
          secondary: Color(0xFFc1c2e7),
          background: Color(0xFF121212),
          surface: Color(0xFF1e1e1e),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      themeMode: themeMode, 
      home: const SplashScreen(), 
    );
  }
}


class RoleRedirectPage extends StatelessWidget {
  const RoleRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    final role = user?.userMetadata?['role'] ?? 'siswa';

    if (email == 'admin@gmail.com' && role == 'admin') {
      return const HomeAdmin();
    }

    if (role == 'pengajar') {
      return const HomePengajar();
    }

    return const HomeSiswa(initialIndex: 0);
  }
}
