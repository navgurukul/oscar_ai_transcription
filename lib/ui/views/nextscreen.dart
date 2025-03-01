import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';



class Nextscreen extends StatefulWidget {
  final String text;
  
  Nextscreen( this.text);

  @override
  State<Nextscreen> createState() => _SecondPageState();
}

class _SecondPageState extends State<Nextscreen> {
  
  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20,bottom: 20),
          child: Center(
            child: Column(
              children: [
                Text(
                  widget.text,
                  style: GoogleFonts.karla(fontSize: 18),
                ),
            
            
              ],
            ),
            
          ),
        ),
      ),
    );
  }
}
