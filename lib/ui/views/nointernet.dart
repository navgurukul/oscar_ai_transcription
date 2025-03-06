import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'auth/login_view.dart';

class NoInternetScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets1/Bad-Connection.png',
              width: 118.31,
              height: 118.31,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No Internet Connection. Please check your connection to continue using Oscar",
                textAlign: TextAlign.center,
                style: GoogleFonts.karla(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4D4D4D)),
              ),
            ),
            TextButton(
              onPressed: (){
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginView()
                ));

              },
              child: Text(
                'Retry',
                style: GoogleFonts.karla(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.ButtonColor2,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: const Color(0xFF51A09B)),
                ),
                backgroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
