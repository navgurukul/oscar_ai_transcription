// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:oscar_stt/core/viewmodels/splash_viewmodel.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../auth/login_view.dart';
// import '../home/home_view.dart';

// class SplashScreen extends StatefulWidget {
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   static const String KEYLOGIN = "Login";




//   @override
//   void initState() {
//     super.initState();
//     _checkSessionAndNavigate();
//   }


//   _checkSessionAndNavigate() async {
//     await Future.delayed(Duration(seconds: 3)); // 3 seconds delay

//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool? isLoggedIn = prefs.getBool(KEYLOGIN);
//     print(isLoggedIn);

//     if (isLoggedIn != null && isLoggedIn) {
//       String profileName = prefs.getString('profileName') ?? '';
//       String profilePicUrl = prefs.getString('profilePicUrl') ?? '';
//       String transcribedata = prefs.getString('transcribedata') ?? '';
//       String tokenid = prefs.getString('tokenid') ?? '';

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => HomePage(
//             profileName: profileName,
//             profilePicUrl: profilePicUrl,
//             transcribedata: transcribedata,
//             tokenid: tokenid,
//           ),
//         ),
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => LoginView()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final imageSize = screenWidth * 0.75;

//     return Scaffold(
//       backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
//       body: Center(
//         child:
//         SvgPicture.asset(
//           'assets1/Oscar Logo with Text.svg',
//           width: imageSize,
//           height: imageSize * 0.75,
//         ),


//       ),
//     );
//   }
// }
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_view.dart';
import '../home/home_view.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String KEYLOGIN = "Login";

  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(Duration(seconds: 3)); // Splash delay
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool(KEYLOGIN);
    String? tokenid = prefs.getString('tokenid'); // Retrieve token
    print(isLoggedIn);

    // Check login and token expiry
    if (isLoggedIn != null && isLoggedIn && tokenid != null && !_isTokenExpired(tokenid)) {
      
      // Retrieve user details if the token is valid
      String profileName = prefs.getString('profileName') ?? '';
      String profilePicUrl = prefs.getString('profilePicUrl') ?? '';
      String transcribedata = prefs.getString('transcribedata') ?? '';
      print('token is not expired');
      // Optionally, get the remaining time until expiry
      Duration timeRemaining = JwtDecoder.getRemainingTime(tokenid);
      print("Time remaining: ${timeRemaining.inMinutes} minutes");
    

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            profileName: profileName,
            profilePicUrl: profilePicUrl,
            transcribedata: transcribedata,
            tokenid: tokenid,
          ),
        ),
      );
    } else {
      // Show dialog and redirect to login if token is expired or user is not logged in
      // print('token is expired');
      // _showTokenExpiryDialog;
      // Redirect to login if not logged in or token is expired
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginView()),
      );
    }
  }


  //  // Function to show a dialog when the token expires
  // void _showTokenExpiryDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false, // Prevent dismissing by tapping outside
  //     builder: (context) => AlertDialog(
  //       title: Text("Session Expired"),
  //       content: Text("Your session has expired. Please log in again."),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop(); // Close the dialog
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => LoginView()),
  //             );
  //           },
  //           child: Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  // // Function to check if the token is expired
  // bool _isTokenExpired(String token) {
  //   try {
  //     return JwtDecoder.isExpired(token);
  //   } catch (e) {
  //     debugPrint("Error decoding token: $e");
  //     return true; // Treat invalid tokens as expired
  //   }
    
  // }

  // Function to check if the token is expired
  bool _isTokenExpired(String token) {
    try {
      // Decode the token to extract the expiry time
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      int expiryTimestamp = decodedToken['exp'] ?? 0;

      // Check if the expiry timestamp is within the next 24 hours (1440 minutes)
      DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
      DateTime currentDate = DateTime.now();
      Duration remainingDuration = expiryDate.difference(currentDate);

      // Check if remaining duration is greater than 24 hours
      return remainingDuration.isNegative || remainingDuration.inMinutes <= 1440;
    } catch (e) {
      debugPrint("Error decoding token: $e");
      return true; // Treat invalid tokens as expired
      // return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.75;

    return Scaffold(
      backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      body: Center(
        child: SvgPicture.asset(
          'assets1/Oscar Logo with Text.svg',
          width: imageSize,
          height: imageSize * 0.75,
        ),
      ),
    );
  }
}
