// SecondPage (Second Page)



import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../auth/login_view.dart';


class SecondPage extends StatefulWidget {
  final String terms;
  final String heading ;
  final launchmail;
  SecondPage( this.terms, this.heading,this.launchmail);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEF6F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFEEF6F5),
        title: Text(widget.heading,style: GoogleFonts.spectral(),),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20,bottom: 20),
          child: Center(
            child: Column(
              children: [
                Text(
                  widget.terms,
                  style: GoogleFonts.karla(fontSize: 18),
                ),
                SizedBox(width: 15,),
                
            InkWell(
              onTap: widget.launchmail,
              child: Text('platforms@samyarth.org',style:GoogleFonts.karla(color: Colors.blue,fontSize: 18),
              ),
            ),
            
              ],
            ),
        
            // InkWell(
            // onTap: () => _launchEmailClient(),
            // child:
            //  Text('platforms@samyarth.org',style: TextStyle(color: Colors.blue,),
            //  ),
            //  ),
            
          ),
        ),
      ),
    );
  }
}
