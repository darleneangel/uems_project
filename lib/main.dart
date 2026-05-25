import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/login_view.dart';
import 'services/supabase_service.dart'; // Import the service from the Canvas
import 'services/navigation_helper.dart';
import 'services/security_service.dart';

// 1. Change main to async to allow for database initialization
void main() async {
  // 2. Mandatory: Ensure Flutter handles are ready before calling native plugins (Supabase/SQLite)
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize the Core Sync Engine
  // Replace these placeholders with your actual project credentials
  try {
    await SupabaseService.init();
    print(' UEMS Engine Initialized Successfully');
  } catch (e) {
    print(' UEMS Initialization Failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final poppins = GoogleFonts.poppins();
    final notoSans = GoogleFonts.notoSans();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'UEMS - Unified Education Management System',
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) => SecurityService().resetInactivityTimer(),
          onPointerMove: (_) => SecurityService().resetInactivityTimer(),
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: poppins.fontFamily,
        fontFamilyFallback: [
          if (notoSans.fontFamily != null) notoSans.fontFamily!,
        ],
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      // This starts the app on the Login Page
      home: const UEMSLoginPage(),
    );
  }
}
