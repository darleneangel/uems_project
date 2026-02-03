import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; //ito ay external packages hehe

class UEMSAdminView extends StatefulWidget {
  const UEMSAdminView({super.key});

  @override
  State<UEMSAdminView> createState() => _UEMSAdminViewState();
}

class _UEMSAdminViewState extends State<UEMSAdminView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins()),
      ),
      body: Center(
        child: Text(
          'Welcome to the Admin Dashboard',
          style: GoogleFonts.poppins(fontSize: 26),
        ),
      ),
    );
  }
}
