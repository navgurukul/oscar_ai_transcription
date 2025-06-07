// import 'dart:convert';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../core/constants/app_colors.dart';
// import '../home/home_view.dart';

// class LoginView extends StatefulWidget {
//   const LoginView({super.key});

//   @override
//   State<LoginView> createState() => _LoginViewState();
// }

// class _LoginViewState extends State<LoginView> {
//   static const String KEYLOGIN = "Login";

//   var googleSignInAccount;
//   String? globalToken5;

//   Future<void> GoogleLogin() async {
//     print('Google login method called');

//     GoogleSignIn _googleSignIn = GoogleSignIn(
//       scopes: [
//         'https://www.googleapis.com/auth/userinfo.email',
//         'openid',
//         'https://www.googleapis.com/auth/userinfo.profile',
//       ],
//     );
//     try {
//       var result = await _googleSignIn.signIn();
//       print(result);
//       googleSignInAccount = result;

//       if (result != null) {
//         String fullName = result.displayName ?? "";
//         List<String> nameParts = fullName.split(' ');

//         String firstName = nameParts.length > 0 ? nameParts[0] : "";
//         String lastName =
//             nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

//         String email = result.email;
//         String profilePicUrl = result.photoUrl ?? "";
//         String? id = result.id;

//         globalToken5 = id;

//         print("Google Sign-In successful");
//         print("First Name: $firstName");
//         print("Last Name: $lastName");
//         print("Email: $email");
//         print("Profile Picture URL: $profilePicUrl");
//         print("ID: $id");
//         print("Google Sign-In successful");
//         await _authWithMeraki(
//             fullName, lastName, email, profilePicUrl, id, context);

//         if (globalToken5 != null) {
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           await prefs.setBool(KEYLOGIN, true);
//           await prefs.setString('profileName', fullName);
//           await prefs.setString('profilePicUrl', profilePicUrl);
//           await prefs.setString('tokenid', globalToken5!);

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Successfully Logged In')),
//           );
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => HomePage(
//                 tokenid: globalToken5!,
//                 profileName: result.displayName ?? "User's Name",
//                 profilePicUrl: result.photoUrl ?? "",
//                 transcribedata: '',
//               ),
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Token is null, authentication failed')),
//           );
//         }
//       } else {
//         print("Sign-in canceled");
//       }
//     } catch (error) {
//       print(error);
//     }
//   }

//   // Post API,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

//   Future<void> _authWithMeraki(String firstName, String lastName, String email,
//       String profilePicUrl, String id, BuildContext context) async {
//     final String apiUrl =
//         'https://dev-oscar.merakilearn.org/api/v1/auth/android/login';
//     // 'https://dev-oscar.merakilearn.org/api#/auth/AuthController_register' ;
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({
//           'firstName': firstName,
//           'lastName': lastName,
//           'profilePicUrl': profilePicUrl,
//           'id': id,
//           'email': email,
//         }),
//       );
//       if (response.statusCode == 201) {
//         final responseBody = json.decode(response.body);
//         setState(() {
//           globalToken5 = responseBody['data']['token'];
//         });
//         print("this is token $globalToken5");
//         print("Backend Authentication successful: $responseBody");
//       } else {
//         print('Failed to authenticate. Status code: ${response.statusCode}');
//         print('Response body: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Authentication failed')),
//         );
//       }
//     } catch (error) {
//       print('Error occurred: $error');

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('An error occurred')),
//       );
//     }
//   }

//   PageController _pageController = PageController();
//   int _currentPage = 0;

//   void _onPageChanged(int page) {
//     setState(() {
//       _currentPage = page;
//     });
//   }

//   void _onDashTap(int page) {
//     _pageController.animateToPage(
//       page,
//       duration: Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     final imageSize = screenWidth * 0.75;
//     final padding = screenWidth * 0.05;

//     return Scaffold(
//       body: Padding(
//         padding: EdgeInsets.all(padding),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             SizedBox(height: screenHeight * 0.2),
//             Expanded(
//               child: PageView(
//                 controller: _pageController,
//                 onPageChanged: _onPageChanged,
//                 children: [
//                   _buildPage2(imageSize),
//                   _buildPage3(imageSize),
//                 ],
//               ),
//             ),
//             SizedBox(height: screenHeight * 0.02),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 GestureDetector(
//                   onTap: () => _onDashTap(0),
//                   child: Container(
//                     width: screenWidth * 0.09,
//                     height: screenHeight * 0.01,
//                     decoration: BoxDecoration(
//                       color: _currentPage == 0
//                           ? AppColors.ButtonColor2
//                           : Colors.grey[400],
//                       borderRadius:
//                           BorderRadius.circular(20), // Set the border radius
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: screenWidth * 0.02),
//                 SizedBox(width: screenWidth * 0.02),
//                 GestureDetector(
//                   onTap: () => _onDashTap(2),
//                   child: Container(
//                     width: screenWidth * 0.09,
//                     height: screenHeight * 0.01,
//                     decoration: BoxDecoration(
//                       color: _currentPage == 2
//                           ? AppColors.ButtonColor2
//                           : Colors.grey[400],
//                       borderRadius:
//                           BorderRadius.circular(20), // Set the border radius
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: screenHeight * 0.03),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: padding),
//               child: Container(
//                 height: screenHeight * 0.06,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(100.0),
//                   border: Border.all(color: AppColors.ButtonColor2, width: 1.0),
//                 ),
//                 child: InkWell(
//                   onTap: () {
//                     GoogleLogin();
//                   },
//                   borderRadius: BorderRadius.circular(100.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: AppColors.ButtonColor2,
//                       borderRadius: BorderRadius.circular(100.0),
//                     ),
//                     padding: EdgeInsets.symmetric(
//                         vertical: screenHeight * 0.015,
//                         horizontal: screenWidth * 0.05),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           height: screenHeight * 0.06,
//                           width: screenWidth * 0.1,
//                           decoration: BoxDecoration(
//                               shape: BoxShape.circle, color: Colors.white),
//                           child: Image.asset(
//                             'assets1/g2.png',
//                             height: screenHeight * 0.05,
//                             width: screenHeight * 0.05,
//                           ),
//                         ),
//                         SizedBox(width: screenWidth * 0.03),
//                         Text(
//                           'Login With Google',
//                           style: GoogleFonts.karla(
//                               color: Colors.white,
//                               fontSize: screenWidth * 0.04),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPage2(double imageSize) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Center(
//           child: SvgPicture.asset(
//             'assets1/Frame.svg',
//             width: imageSize,
//             height: imageSize * 0.85,
//           ),
//         ),
//         SizedBox(height: 20.0),
//         Container(
//           padding: EdgeInsets.all(16.0),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//           child: Column(
//             children: [
//               Text(
//                 'Speak Your Thoughts',
//                 style: GoogleFonts.spectral(
//                   fontSize: 25.0,
//                   color: Colors.black87,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 15),
//               Text(
//                 'Let your voice express the innovative ideas effortlessly',
//                 style: GoogleFonts.karla(
//                   fontSize: 15.0,
//                   color: Colors.black87,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPage3(double imageSize) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Center(
//           child: SvgPicture.asset(
//             'assets1/Frame5.svg',
//             width: imageSize,
//             height: imageSize * 0.85,
//           ),
//         ),
//         SizedBox(height: 20.0),
//         Container(
//           padding: EdgeInsets.all(16.0),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//           child: Column(
//             children: [
//               Text(
//                 "Let AI Do It's Magic",
//                 style: GoogleFonts.spectral(
//                   fontSize: 25.0,
//                   color: Colors.black87,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 15),
//               Text(
//                 'Your spoken words turned into clear and polished text',
//                 style: GoogleFonts.karla(
//                   fontSize: 14.5,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.black87,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }




// __________________________________________________________________________________________________


import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../home/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Constants
  static const String _keyLogin = "Login";
  static const String _apiUrl = 'https://dev-oscar.merakilearn.org/api/v1/auth/android/login';

  // State variables
  var _googleSignInAccount;
  String? _globalToken;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // UI Constants
  late final double _screenWidth;
  late final double _screenHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(_screenWidth * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: _screenHeight * 0.2),
            _buildPageView(),
            SizedBox(height: _screenHeight * 0.02),
            _buildPageIndicator(),
            SizedBox(height: _screenHeight * 0.03),
            _buildGoogleLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildOnboardingPage(
            imagePath: 'assets1/Frame.svg',
            title: 'Speak Your Thoughts',
            description: 'Let your voice express the innovative ideas effortlessly',
          ),
          _buildOnboardingPage(
            imagePath: 'assets1/Frame5.svg',
            title: "Let AI Do It's Magic",
            description: 'Your spoken words turned into clear and polished text',
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    final imageSize = _screenWidth * 0.75;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SvgPicture.asset(
            imagePath,
            width: imageSize,
            height: imageSize * 0.85,
          ),
        ),
        SizedBox(height: 20.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.spectral(
                  fontSize: 25.0,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                description,
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

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIndicatorDot(0),
        SizedBox(width: _screenWidth * 0.02),
        _buildIndicatorDot(1),
      ],
    );
  }

  Widget _buildIndicatorDot(int pageIndex) {
    return GestureDetector(
      onTap: () => _onDashTap(pageIndex),
      child: Container(
        width: _screenWidth * 0.09,
        height: _screenHeight * 0.01,
        decoration: BoxDecoration(
          color: _currentPage == pageIndex
              ? AppColors.ButtonColor2
              : Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _screenWidth * 0.05),
      child: Container(
        height: _screenHeight * 0.06,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100.0),
          border: Border.all(color: AppColors.ButtonColor2, width: 1.0),
        ),
        child: InkWell(
          onTap: _handleGoogleLogin,
          borderRadius: BorderRadius.circular(100.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ButtonColor2,
              borderRadius: BorderRadius.circular(100.0),
            ),
            padding: EdgeInsets.symmetric(
              vertical: _screenHeight * 0.015,
              horizontal: _screenWidth * 0.05,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: _screenHeight * 0.06,
                  width: _screenWidth * 0.1,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Image.asset(
                    'assets1/g2.png',
                    height: _screenHeight * 0.05,
                    width: _screenHeight * 0.05,
                  ),
                ),
                SizedBox(width: _screenWidth * 0.03),
                Text(
                  'Login With Google',
                  style: GoogleFonts.karla(
                    color: Colors.white,
                    fontWeight : FontWeight.bold,
                    fontSize: _screenWidth * 0.05,
                    // fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onDashTap(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await _signInWithGoogle();
      if (_googleSignInAccount != null) {
        await _authenticateWithBackend();
        await _saveUserDataToPrefs();
        _navigateToHome();
      }
    } catch (error) {
      _showErrorSnackbar('Login failed: $error');
    }
  }

  Future<void> _signInWithGoogle() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/userinfo.email',
        'openid',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
    
    final result = await _googleSignIn.signIn();
    if (result == null) {
      throw Exception('Sign-in canceled');
    }

    _googleSignInAccount = result;
    _globalToken = result.id;
  }

  Future<void> _authenticateWithBackend() async {
    final fullName = _googleSignInAccount.displayName ?? "";
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : "";
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";
    final email = _googleSignInAccount.email;
    final profilePicUrl = _googleSignInAccount.photoUrl ?? "";
    final id = _googleSignInAccount.id;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'profilePicUrl': profilePicUrl,
          'id': id,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        setState(() {
          _globalToken = responseBody['data']['token'];
        });
      } else {
        throw Exception('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }

  Future<void> _saveUserDataToPrefs() async {
    if (_globalToken == null) {
      throw Exception('Token is null');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLogin, true);
    await prefs.setString('profileName', _googleSignInAccount.displayName ?? "");
    await prefs.setString('profilePicUrl', _googleSignInAccount.photoUrl ?? "");
    await prefs.setString('tokenid', _globalToken!);
  }

  void _navigateToHome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          tokenid: _globalToken!,
          profileName: _googleSignInAccount.displayName ?? "User's Name",
          profilePicUrl: _googleSignInAccount.photoUrl ?? "",
          transcribedata: '',
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}