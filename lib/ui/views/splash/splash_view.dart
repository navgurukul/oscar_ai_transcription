
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:testing_oscar/ui/views/CombinedScreen.dart';
import '../../../core/constants/app_colors.dart';
import '../CombinedScreen.dart';
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
    await Future.delayed(Duration(seconds: 3));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool(KEYLOGIN);
    String? tokenid = prefs.getString('tokenid');
    if (isLoggedIn == null || !isLoggedIn || tokenid == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginView()),
      );
      return;
    }

    if (_isTokenExpired(tokenid)) {
      _showSessionExpiredDialog(); 
    } else {
      String profileName = prefs.getString('profileName') ?? '';
      String profilePicUrl = prefs.getString('profilePicUrl') ?? '';
      String transcribedata = prefs.getString('transcribedata') ?? '';

      Duration timeRemaining = JwtDecoder.getRemainingTime(tokenid);
      print("Time remaining: ${timeRemaining.inMinutes} minutes");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                CombinedPage(profileName: profileName, profilePicUrl: profilePicUrl, tokenid: tokenid, controller: ManualSttController(context),)
          //     HomePage(
          //   profileName: profileName,
          //   profilePicUrl: profilePicUrl,
          //   transcribedata: transcribedata,
          //   tokenid: tokenid,
          // ),
        ),
      );
    }
  }

  bool _isTokenExpired(String token) {
    try {
      
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      int expiryTimestamp = decodedToken['exp'] ?? 0;

      DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
      DateTime currentDate = DateTime.now();
      Duration remainingDuration = expiryDate.difference(currentDate);

      return remainingDuration.isNegative || remainingDuration.inMinutes <= 1440;
    } catch (e) {
      debugPrint("Error decoding token: $e");
      return true; 
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text("Session Expired"),
          content: Text("Your session has expired. Please log in again."),
          actions: [
            TextButton(onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginView()));
            },
              child: Container(
                // width: 5,
                decoration: BoxDecoration(
                  color: AppColors.ButtonColor2,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.white),
                ),
              ),)
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.75;

<<<<<<< HEAD
    return Scaffold(
      backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      body: Center(
        child: SvgPicture.asset(
          'assets1/logo.svg',
          width: 116,
          height: 120,
=======
    return
      Scaffold(
        backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
        body: Center(
          child: SvgPicture.asset(
            'assets1/Oscar Logo with Text.svg',
            width: imageSize,
            height: imageSize * 0.75,
          ),
>>>>>>> transcription_list
        ),
      );
  }
}
