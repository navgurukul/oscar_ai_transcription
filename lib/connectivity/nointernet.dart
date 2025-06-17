// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:oscar_stt/core/constants/app_colors.dart';
// import 'package:oscar_stt/ui/views/profile/profile_view.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'auth/login_view.dart';



// class NoInternetScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar:  AppBar(
//           backgroundColor: Colors.white,
//           scrolledUnderElevation: 0.0,
//           automaticallyImplyLeading: false,
//           elevation: 0,
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SvgPicture.asset(
//                 'assets1/Frame 31584.svg',
//                 width: 98,
//                 height: 32,
//               ),
//               IconButton(
//                 icon: CircleAvatar(
//                   backgroundImage: widget.profilePicUrl != null &&
//                           widget.profilePicUrl!.isNotEmpty
//                       ? NetworkImage(widget.profilePicUrl!)
//                       : null,
//                   radius: mq.width * 0.04,
//                   backgroundColor: Colors.blue,
//                   child: widget.profilePicUrl == null ||
//                           widget.profilePicUrl!.isEmpty
//                       ? Text(
//                           widget.profileName.isNotEmpty
//                               ? widget.profileName[0].toUpperCase()
//                               : '',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: mq.width * 0.04,
//                           ),
//                         )
//                       : null,
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => SettingsScreen(
//                               profileName: widget.profileName,
//                               profilePicUrl: widget.profilePicUrl)));
//                 },
//               )
//             ],
//           ),
//         ),
      
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               'assets1/Bad-Connection.png',
//               width: 118.31,
//               height: 118.31,
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 20),
//               child: Text(
//                 "No Internet Connection. Please check your connection to continue using Oscar",
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.karla(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w400,
//                     color: const Color(0xFF4D4D4D)),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pushReplacement(
//                     MaterialPageRoute(builder: (context) => LoginView()));
//               },
//               child: Text(
//                 'Retry',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: AppColors.ButtonColor2,
//                 ),
//               ),
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   side: BorderSide(color: const Color(0xFF51A09B)),
//                 ),
//                 backgroundColor: Colors.white,
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// _________________________________________________________________________________________________

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:oscar_stt/core/constants/app_colors.dart';
// import 'package:oscar_stt/ui/views/profile/profile_view.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../ui/views/auth/login_view.dart';

// class NoInternetScreen extends StatelessWidget {
//   // Helper method to get token from SharedPreferences
//   Future<String?> getToken() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('tokenid');
//   }

//   // Helper method to get profile name from SharedPreferences
//   Future<String?> getProfileName() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('profileName');
//   }

//   // Helper method to get profile picture URL from SharedPreferences
//   Future<String?> getProfilePicUrl() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('profilePicUrl');
//   }

//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;
//     final screenWidth = MediaQuery.of(context).size.width;
    
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         scrolledUnderElevation: 0.0,
//         automaticallyImplyLeading: false,
//         elevation: 0,
//         title: FutureBuilder<List<String?>>(
//           future: Future.wait([
//             getProfileName(),
//             getProfilePicUrl(),
//             getToken(),
//           ]),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   SvgPicture.asset(
//                     'assets1/Frame 31584.svg',
//                     width: 98,
//                     height: 32,
//                   ),
//                   CircleAvatar(
//                     radius: mq.width * 0.04,
//                     backgroundColor: Colors.grey[300],
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 ],
//               );
//             }

//             if (snapshot.hasError) {
//               return Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   SvgPicture.asset(
//                     'assets1/Frame 31584.svg',
//                     width: 98,
//                     height: 32,
//                   ),
//                   IconButton(
//                     icon: CircleAvatar(
//                       radius: mq.width * 0.04,
//                       backgroundColor: Colors.grey[300],
//                       child: Icon(Icons.error, color: Colors.white),
//                     ),
//                     onPressed: () {},
//                   )
//                 ],
//               );
//             }

//             final profileName = snapshot.data?[0] ?? '';
//             final profilePicUrl = snapshot.data?[1] ?? '';
//             final token = snapshot.data?[2] ?? '';

//             return Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 SvgPicture.asset(
//                   'assets1/Frame 31584.svg',
//                   width: 98,
//                   height: 32,
//                 ),
//                 IconButton(
//                   icon: CircleAvatar(
//                     backgroundImage: profilePicUrl.isNotEmpty
//                         ? NetworkImage(profilePicUrl)
//                         : null,
//                     radius: mq.width * 0.04,
//                     backgroundColor: Colors.blue,
//                     child: profilePicUrl.isEmpty
//                         ? Text(
//                             profileName.isNotEmpty
//                                 ? profileName[0].toUpperCase()
//                                 : '',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: mq.width * 0.04,
//                             ),
//                           )
//                         : null,
//                   ),
//                   onPressed: () {
//                     if (token.isNotEmpty) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => SettingsScreen(
//                             profileName: profileName,
//                             profilePicUrl: profilePicUrl,
//                           ),
//                         ),
//                       );
//                     }
//                   },
//                 )
//               ],
//             );
//           },
//         ),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SvgPicture.asset(
//               'assets1/Bad Connection 3 2.svg',
//               width: 118.31,
//               height: 82.31,
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 20),
//               child: Text(
//                 "No Internet Connection. Please check your connection to continue using Oscar",
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: const Color(0xFF4D4D4D),
//                 ),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (context) => LoginView()),
//                 );
//               },
//               child: Text(
//                 'Retry',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.ButtonColor2,
//                 ),
//               ),
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   side: BorderSide(color: const Color(0xFF51A09B)),
//                 ),
//                 backgroundColor: Colors.white,
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
// _____________________________________________

// // 15/06/2025

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:oscar_stt/ui/views/home/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'home_view.dart'; // update path as needed

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key, required Null Function() onRetry});

  Future<void> _retry(BuildContext context) async {
    final result = await Connectivity().checkConnectivity();

    if (result != ConnectivityResult.none) {
      // ✅ Internet is back → Load saved values
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('tokenid');
      String? name = prefs.getString('profileName');
      String? pic = prefs.getString('profilePicUrl');

      if (token != null && name != null && pic != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              tokenid: token,
              profileName: name,
              profilePicUrl: pic,
              transcribedata: '',
            ),
          ),
          (route) => false,
        );
      } else {
        // 🔒 If info missing, send back to Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired, please login again")),
        );
        // Navigator.pushReplacement(... LoginView);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Still no internet")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: 
      // Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       const Icon(Icons.wifi_off, size: 80, color: Colors.red),
      //       const SizedBox(height: 20),
      //       const Text('No Internet Connection', style: TextStyle(fontSize: 20)),
      //       const SizedBox(height: 20),
      //       ElevatedButton(
      //         onPressed: () => _retry(context),
      //         child: const Text("Retry"),
      //       ),
      //     ],
      //   ),
      // ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets1/Bad Connection 3 2.svg',
              width: 118.31,
              height: 82.31,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No Internet Connection. Please check your connection to continue using Oscar",
                textAlign: TextAlign.center,
                style: GoogleFonts.karla(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4D4D4D),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _retry(context);
                // Navigator.of(context).pushReplacement(
                //   MaterialPageRoute(builder: (context) => LoginView()),
                // );
              },
              child: Text(
                'Retry',
                style: GoogleFonts.karla(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
