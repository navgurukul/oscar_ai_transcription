

import 'dart:io';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../auth/login_view.dart';

// AgreementHelper class
class AgreementHelper {
  static const _agreementFileName = 'user_agreement.txt';
  static const _termsOfUseFileName = 'user_terms_of_use.txt';

  static Future<bool> hasAgreed() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_agreementFileName');
    return file.exists();
  }

  static Future<void> markAsAgreed() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_agreementFileName');
    await file.writeAsString('Agreed');
  }

  static Future<bool> hasAgreedToTerms() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_termsOfUseFileName');
    return file.exists();
  }

  static Future<void> markAsAgreedToTerms() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_termsOfUseFileName');
    await file.writeAsString('Agreed');
  }
}

class SettingsScreen extends StatefulWidget {
  final String profileName;
  final String profilePicUrl;

  SettingsScreen({
    Key? key,
    required this.profileName,
    required this.profilePicUrl,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color greenContainerColor = Color(0xFF51A09B);
  final Color signOutColor = Color(0xFF4D4D4D);
  final String contactEmail = 'support.oscar@samyarth.org';
  bool _hasAgreed = false;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();
  }

  Future<void> _checkAgreementStatus() async {
    final hasAgreed = await AgreementHelper.hasAgreed();
    setState(() {
      _hasAgreed = hasAgreed;
    });
  }

  final String termsOfUseText =  '''


1. By using the Oscar Keyboard App ("App"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree with these Terms, you should not use the App.

2. The Oscar Keyboard App is a third-party integrable speech-to-text converter keyboard intended for use on Android devices. It allows users to input text via voice.

3. You are responsible for maintaining the confidentiality of your account and password and for using the App in compliance with all applicable laws and regulations. You agree not to misuse the App or attempt to interfere with its operation.

4. The App is licensed, not sold, to you. Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to use the App.

5. You agree not to decompile, reverse engineer, or disassemble the App, use the App for any illegal or unauthorized purpose, or modify or create derivative works based on the App.

6. We reserve the right to terminate or suspend your access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users.

7. The App is provided "as is" and "as available," without warranties of any kind, either express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, or non-infringement.

8. In no event shall Samyarth, its affiliates, or its licensors be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses, resulting from your use or inability to use the App, any unauthorized access to or use of our servers and/or any personal information stored therein, any interruption or cessation of transmission to or from the App, any bugs, viruses, trojan horses, or the like that may be transmitted to or through the App by any third party, or any errors or omissions in any content or for any loss or damage incurred as a result of the use of any content posted, emailed, transmitted, or otherwise made available through the App, whether based on warranty, contract, tort (including negligence), or any other legal theory, whether or not we have been informed of the possibility of such damage.

9. These Terms shall be governed and construed in accordance with the laws of Uttar Pradesh(India), without regard to its conflict of law provisions.

10. We reserve the right to modify these Terms at any time. Your continued use of the App after any such changes constitutes your acceptance of the new Terms.

11. If you have any questions about these Terms, please contact us at support.oscar@samyarth.org.
  ''';

  final String privacyPolicyText =  '''


1. We value your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the Oscar Keyboard App.

2. We collect personal information such as your email address and user preferences when you create an account or use the App. We also collect information about your usage of the App, such as the features you use, the time and duration of your use, and error reports.

3. We use your information to provide and maintain the App, improve and personalize your experience, monitor and analyze usage and trends, send you updates, security alerts, and support messages, and comply with legal obligations.

4. We do not share your personal information with third parties except with your consent, to comply with legal requirements, or to protect and defend our rights and property.

5. We implement appropriate technical and organizational measures to protect your personal data from unauthorized access, use, or disclosure.

6. We retain your personal data only for as long as necessary to fulfill the purposes for which it was collected or as required by law.

7. Depending on your jurisdiction, you may have the following rights regarding your personal data: access to your data, correction of inaccurate data, deletion of your data, restriction of processing, and data portability.

8. The App is not intended for use by children under the age of 13. We do not knowingly collect personal data from children under 13. If we learn that we have collected personal data from a child under 13, we will delete that information promptly.

9. We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the App. Your continued use of the App after any such changes constitutes your acceptance of the new Privacy Policy.

10. If you have any questions about this Privacy Policy, please contact us at support.oscar@samyarth.org


  ''';

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),

      // backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: mq.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: mq.height * 0.05),
            Center(
              child: Text(
                'Account Details',
                style: TextStyle(
                  fontSize: mq.width * 0.09,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: mq.height * 0.10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: mq.width * 0.18,
                  height: mq.width * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.transparent, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: mq.width * 0.09,
                    backgroundImage: widget.profilePicUrl.isNotEmpty
                        ? NetworkImage(widget.profilePicUrl)
                        : null,
                    child: widget.profilePicUrl.isEmpty
                        ? Icon(Icons.person, size: mq.width * 0.08)
                        : null,
                  ),
                ),
                SizedBox(width: mq.width * 0.03),
                Text(widget.profileName, style: TextStyle(fontSize: mq.width * 0.05)),
              ],
            ),
            SizedBox(height: mq.height * 0.02),
            Expanded(
              child: ListView.separated(
                itemCount: 3,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey),
                itemBuilder: (context, index) {
                  IconData iconData;
                  String title;
                  switch (index) {
                    case 0:
                      iconData = Icons.book_outlined;
                      title = "Terms of use";
                      break;
                    case 1:
                      iconData = Icons.privacy_tip_outlined;
                      title = "Privacy policy";
                      break;
                    case 2:
                      iconData = Icons.mail_outline;
                      title = "Email us";
                      break;
                    default:
                      iconData = Icons.info_outline;
                      title = "Information";
                      break;
                  }
                  return ListTile(
                    leading: Icon(iconData, color: greenContainerColor),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16.0,
                        ),
                      ],
                    ),
                    onTap: () {
                      if (index == 0) {
                        _showTermsOfUseDialog(context, termsOfUseText);
                      } else if (index == 1) {
                        _showPrivacyPolicyDialog(context, privacyPolicyText);
                      } else if (index == 2) {
                        _launchEmailClient();
                      }
                    },
                  );
                },
              ),
            ),

            _buildCustomSignOutButton(context),


          ],
        ),
      ),
    );
  }


  Widget _buildCustomSignOutButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Adjust padding as needed
      child: Align(
        alignment: Alignment.bottomLeft, // Align to the bottom left of the screen
        child: GestureDetector(
          onTap: () async {
            await GoogleSignIn().signOut();
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('isLoggedIn');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginView()),
                  (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Log out..')),
            );
          },
          child: Container(
            width: 120,
            height: 50,
            decoration: BoxDecoration(
              color:AppColors.ButtonColor2,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text(
                'Log Out',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTermsOfUseDialog(BuildContext context, String termsOfUseText) async {
    final hasAgreedToTerms = await AgreementHelper.hasAgreedToTerms();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Terms of Use",style: GoogleFonts.karla(),),
          content: SingleChildScrollView(
            child: Text(termsOfUseText),
          ),
          actions: [
            if (!hasAgreedToTerms)
              TextButton(
                child: Text("Agree",style: GoogleFonts.karla(color: Colors.green),),
                onPressed: () async {
                  await AgreementHelper.markAsAgreedToTerms();
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPrivacyPolicyDialog(BuildContext context, String privacyPolicyText) async {
    final hasAgreedToTerms = await AgreementHelper.hasAgreedToTerms();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Privacy Policy"),
          content: SingleChildScrollView(
            child: Text(privacyPolicyText),
          ),
          actions: [
            if (!hasAgreedToTerms)
              TextButton(
                child: Text("Agree",style: GoogleFonts.karla(color: Colors.green),),
                onPressed: () async {
                  await AgreementHelper.markAsAgreedToTerms();
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  // Future<void> _launchEmailClient() async {
  //   final Email email = Email(
  //     body: '',
  //     subject: 'Support Request',
  //     recipients: [contactEmail],
  //     isHTML: false,
  //   );
  //
  //   try {
  //     await FlutterEmailSender.send(email);
  //
  //     // If email is successfully sent, show success popup
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Email sent successfully'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (error) {
  //     // Handle failure or if the email is not sent
  //     print('Email not sent: $error');
  //   }
  // }

  //
  //
    Future<void> _launchEmailClient() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: contactEmail,
    );
    try {
      await launch(emailLaunchUri.toString());
    } catch (e) {
      print('Could not launch email client');
    }
  }


  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries.map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
  }
}
