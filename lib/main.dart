import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  //HELLO
  @override
  Widget build(BuildContext context) {
    final poppins = GoogleFonts.poppins();
    final notoSans = GoogleFonts.notoSans();

    return MaterialApp(
      title: 'UEMS - Unified Education Management System',
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
