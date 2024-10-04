

import 'dart:convert';

import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oscar_stt/ui/views/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {

  static const String KEYLOGIN = "Login"; // Define the constant here

  var googleSignInAccount;
  String? globalToken5;

  Future<void> GoogleLogin() async {
    print('Google login method called');

    GoogleSignIn _googleSignIn = GoogleSignIn(
      // clientId: "229869143761-q39p62le5ettq8suss0qj7elpqq5pk9i.apps.googleusercontent.com",  //from this app
//clientId: "229869143761-q39p62le5ettq8suss0qj7elpqq5pk9i.apps.googleusercontent.com", //Old one
//clientId: "361814667544-pf7l8b9hik69709hh5hcujgcjrc6e1jg.apps.googleusercontent.com",
//clientId: "361814667544-p0jkacu1vs23tbtv5sfil1dln4v410kv.apps.googleusercontent.com",
clientId: "89230287346-710j4dvn558bpgi9i2dqa4chofoorqb5.apps.googleusercontent.com",

    scopes: [
        'https://www.googleapis.com/auth/userinfo.email',
        'openid',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
    try {
      var result = await _googleSignIn.signIn();
      print(result);
      googleSignInAccount = result;

      if (result != null) {
        String fullName = result.displayName ?? "";
        List<String> nameParts = fullName.split(' ');

        String firstName = nameParts.length > 0 ? nameParts[0] : "";
        String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

        String email = result.email;
        String profilePicUrl = result.photoUrl ?? "";
        String? id = result.id;

        globalToken5 = id;  /// when i use here then able to do login

        print("Google Sign-In successful");
        print("First Name: $firstName");
        print("Last Name: $lastName");
        print("Email: $email");
        print("Profile Picture URL: $profilePicUrl");
        print("ID: $id");
        print("Google Sign-In successful");
        await _authWithMeraki(fullName,lastName, email, profilePicUrl, id, context);


        if (globalToken5 != null) {

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(KEYLOGIN, true);
          await prefs.setString('profileName', fullName);
          await prefs.setString('profilePicUrl', profilePicUrl);
          await prefs.setString('tokenid', globalToken5!);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully Logged In')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                   HomePage(
                tokenid: globalToken5!,
                profileName: result.displayName ?? "User's Name",
                profilePicUrl: result.photoUrl ?? "",
                transcribedata: '',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Token is null, authentication failed')),
          );
        }
      } else {
        print("Sign-in canceled");
      }
    } catch (error) {
      print(error);
    }
  }


  // Post API,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

  Future<void> _authWithMeraki(String firstName, String lastName,String email, String profilePicUrl, String id, BuildContext context) async {
    final String apiUrl = 'https://dev-oscar.merakilearn.org/api/v1/auth/android/login';
        // 'https://dev-oscar.merakilearn.org/api#/auth/AuthController_register' ;
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          // 'lastName': "",
          'profilePicUrl': profilePicUrl,
          'id': id,
          'email': email,
          // 'lastName' : lastName,
        }),);
      if (response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        setState(() {
          globalToken5 = responseBody['data']['token'];
        });
        print("this is token $globalToken5");
        print("Backend Authentication successful: $responseBody");

      } else {
        print('Failed to authenticate. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed')),
        );
      }
    } catch (error) {
      print('Error occurred: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }


  PageController _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onDashTap(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final imageSize = screenWidth * 0.75;
    final padding = screenWidth * 0.05;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: screenHeight * 0.2),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPage1(imageSize),
                  _buildPage2(imageSize),
                  _buildPage3(imageSize),

                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                GestureDetector(
                  onTap: () => _onDashTap(0),
                  child: Container(
                    width: screenWidth * 0.09,
                    height: screenHeight * 0.01,
                    decoration: BoxDecoration(
                      color: _currentPage == 0 ? AppColors.ButtonColor2 : Colors.grey[400],
                      borderRadius: BorderRadius.circular(20), // Set the border radius
                    ),                  ),
                ),
                SizedBox(width: screenWidth * 0.02),

                GestureDetector(
                  onTap: () => _onDashTap(1),
                  child: Container(
                    width: screenWidth * 0.09,
                    height: screenHeight * 0.01,
                    decoration: BoxDecoration(
                      color: _currentPage == 1 ? AppColors.ButtonColor2 : Colors.grey[400],
                      borderRadius: BorderRadius.circular(20), // Set the border radius
                    ),                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                GestureDetector(
                  onTap: () => _onDashTap(2),
                  child: Container(
                    width: screenWidth * 0.09,
                    height: screenHeight * 0.01,
                    decoration: BoxDecoration(
                      color: _currentPage == 2 ? AppColors.ButtonColor2 : Colors.grey[400],
                      borderRadius: BorderRadius.circular(20), // Set the border radius
                    ),                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Container(
                height: screenHeight * 0.06,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.0),
                  border: Border.all(color: AppColors.ButtonColor2, width: 1.0),
                ),
                child: InkWell(
                  onTap: () {
                    GoogleLogin();
                  },
                  borderRadius: BorderRadius.circular(100.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.ButtonColor2,
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015, horizontal: screenWidth * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: screenHeight * 0.06,
                          width: screenWidth * 0.1,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: Image.asset(
                            'assets1/g2.png',
                            height: screenHeight * 0.05,
                            width: screenHeight * 0.05,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Login with Google',
                          style: GoogleFonts.karla(color: Colors.white, fontSize: screenWidth * 0.04),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2(double imageSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child:

          SvgPicture.asset(
            'assets1/Frame.svg',
            width: imageSize,
            height: imageSize * 0.85,
          ),

        ),
        SizedBox(height: 20.0),
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              Text(
                'Speech your thoughts',
                style: GoogleFonts.spectral(
                  fontSize: 25.0,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                'Simply talk, and let your voice express your ideas',
                style: GoogleFonts.karla(
                  fontSize: 15.0,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage3(double imageSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child:

          SvgPicture.asset(
      'assets1/Frame5.svg',
      width: imageSize,
      height: imageSize * 0.85,
    ),


        ),
        SizedBox(height: 20.0),
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              Text(
                "Let AI Do it's magic",
                style: GoogleFonts.spectral(
                  fontSize: 25.0,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                'Our AI instantly converts your spoken words into clear polished text',
                style: GoogleFonts.karla(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildPage1(double imageSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Center(
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                SizedBox(height: 35),

                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Speak it',
                        style: GoogleFonts.spectral(
                          fontSize: 38.0,
                          color: Colors.black87, // 'Speak it' in black
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '. ', // Dot in green
                        style: GoogleFonts.francoisOne(
                          fontSize: 25.0,
                          color: AppColors.ButtonColor2, // Dot color in green
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: 'See it',
                        style: GoogleFonts.spectral(
                          fontSize: 38.0,
                          color: Colors.black87, // 'See it' in black
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '. ', // Dot in green
                        style: GoogleFonts.francoisOne(
                          fontSize: 25.0,
                          color: AppColors.ButtonColor2, // Dot color in green
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 5),




                Text(
                  "Save it or Share it.",
                  style: GoogleFonts.spectral(
                    fontSize: 35.0,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  "Effortlessly.",
                  style: GoogleFonts.spectral(
                    fontSize: 35.0,
                    color: AppColors.ButtonColor2,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),


              ],
            ),
          ),
        ),
      ],
    );
  }

}








