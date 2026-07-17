import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'views/chat_view.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseOptions.supabaseUrl,
    anonKey: SupabaseOptions.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color _bg = Color(0xFF0B1020);
  static const Color _surface = Color(0xFF141B2D);
  static const Color _surfaceSoft = Color(0xFF1A2238);
  static const Color _primary = Color(0xFF8B7CFF);
  static const Color _accent = Color(0xFF63E6FF);
  static const Color _text = Color(0xFFF3F5FF);
  static const Color _muted = Color(0xFFB6BED8);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bg,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        secondary: _accent,
        surface: _surface,
        surfaceContainerHighest: _surfaceSoft,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: _text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: _text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        labelStyle: const TextStyle(color: _muted),
        hintStyle: const TextStyle(color: _muted),
        prefixIconColor: _muted,
        suffixIconColor: _muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: _text,
          side: BorderSide(color: Colors.white.withOpacity(0.10)),
          backgroundColor: _surface.withOpacity(0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceSoft,
        contentTextStyle: const TextStyle(color: _text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel()..listenToAuthChanges(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Kolyas Messenger',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Supabase.instance.client.auth.currentSession != null
            ? const ChatView()
            : const LoginView(),
      ),
    );
  }
}