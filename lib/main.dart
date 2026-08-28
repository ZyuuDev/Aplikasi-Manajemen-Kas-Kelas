import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sesi supabase_flutter persist antar-buka aplikasi: jika masih ada,
    // langsung ke dashboard tanpa login ulang.
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      title: 'SakuKelas Bendahara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: hasSession ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
