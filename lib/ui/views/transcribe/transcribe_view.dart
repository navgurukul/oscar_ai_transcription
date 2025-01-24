import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:oscar_stt/ui/views/auth/login_view.dart';
import 'package:oscar_stt/ui/views/nointernet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../record/record_view.dart';

class TranscribeResult extends StatefulWidget {
  final String transcribedText;
  final String title_text;
  final String unformattedText;
  final VoidCallback? onDelete;
  final String tokenid;
  final bool isEmptyInput;

  const TranscribeResult(
      {Key? key,
        required this.transcribedText,
        this.onDelete,
        required this.tokenid,
        required this.isEmptyInput,
        required this.unformattedText,
        required this.title_text})
      : super(key: key);

  @override
  State<TranscribeResult> createState() => _TranscribeResultState();
}

class _TranscribeResultState extends State<TranscribeResult>  with SingleTickerProviderStateMixin{
  late TextEditingController _textController;
  late TextEditingController _text_titleController;
  late TextEditingController _notFormattedText;
  bool _showTranscribedText = false;
  bool _isEditing = false;
  late TabController _tabController;
  final Connectivity _connectivity = Connectivity();
  late final Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.transcribedText);
    _notFormattedText = TextEditingController(text: widget.unformattedText);
    _text_titleController = TextEditingController(text: widget.title_text);
    _tabController = TabController(length: 2, vsync: this);
    _textController = TextEditingController(text: widget.transcribedText);
    _notFormattedText = TextEditingController(text: widget.unformattedText);
    super.initState();
    _connectivityStream =
        _connectivity.onConnectivityChanged.cast<ConnectivityResult>();

    _monitorInternet();

  }


  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // Navigate to the NoInternetScreen
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NoInternetScreen(),
        ));
      }
    });
  }

  void checkInput({required bool isEmptyInput}) {
  if (isEmptyInput) {
    print("Input is empty.");
  } else {
    print("Input is provided.");
  }
}


  void _handleBack() {
    Navigator.pop(context, 'show_popup'); // Pass a specific result
  }

  void _shareText() {
    try {
      Share.share(_textController.text);
      print('Text shared successfully');
    } catch (e) {
      print('Error sharing text: $e');
    }
  }

  Future<void> _deleteTranscription(BuildContext context) async {
    widget.onDelete!(); // Perform the delete operation
    Navigator.pop(context, 'Transcription deleted');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transcription deleted')),
    );
    // Pop the current screen with the message
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  Future<void> _sendTranscriptionToBackend() async {
    final String apiUrl = 'https://dev-oscar.merakilearn.org/api/v1/transcriptions/add';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': 'Bearer ${widget.tokenid}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'transcribedText': _textController.text,
          'userTextInput': _notFormattedText.text,
          'title': _text_titleController.text // Added to check....
        }),
      );
      if (response.statusCode == 201) {
        print('Transcription successfully sent: ${response.statusCode}');
        // print();
        Navigator.pop(context, 'Saved transcription');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved transcription')),
        );
      }
      // added below else if condition for error 401 , invalid token 
      else if (response.statusCode == 401) {

        print(' Invalid token: ${response.statusCode}');
        // Show AlertDialog
        showDialog(
          context: context,
          barrierDismissible:
              false, // Prevent dialog from closing on tap outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Session Expired'),
              content: Text('Your token is expired and you are logged out.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog

                    // Sign out and clear session
                    await GoogleSignIn().signOut();
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.remove('isLoggedIn');

                    // Navigate to LoginView
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginView()),
                      (route) => false,
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
      else {
        print('Failed to send transcription: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during sending transcription: $e');
    }
  }


  void _navigateToRecordView() {
    Navigator.pushNamed(context, '/recordView').then((_) {
      // Start the recording and timer here
      print('Recording started');
    });
  }


  @override
  void didUpdateWidget(covariant TranscribeResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transcribedText != oldWidget.transcribedText) {
      // Update the text controller if the transcribed text changes
      _textController.text = widget.transcribedText;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: mq.width * 0.04),
            onPressed: _handleBack),
            backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF51A09B), // Custom indicator color
          indicatorWeight: 4.0,
          indicatorPadding: EdgeInsets.symmetric(horizontal: 20.0), // Padding
          labelColor: const Color(0xFF51A09B), // Active tab text color
          unselectedLabelColor:
              const Color(0xFF6E6E6E), // Inactive tab text color
          labelStyle: GoogleFonts.karla(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            // TextStyle for unselected tab
          ),
          unselectedLabelStyle: GoogleFonts.karla(
            fontSize: 16,
            fontWeight: FontWeight.w700, // TextStyle for unselected tab
          ),
          tabs: [
            Tab(
              text: "Polished Text",
            ),
            Tab(text: "Original Text"),
          ],
        ),),
      
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text_titleController.text,
                  style: GoogleFonts.spectral(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                // Text(
                //   // _textController.text,
                //   _textController.text,
                //   style: GoogleFonts.karla(
                //     fontSize: 16,
                //     color: const Color(0xFF6E6E6E),
                //     fontWeight: FontWeight.w400,
                //   ),
                // ),
                // SizedBox(
                //   height: 10,
                // ),
                Text(
                  // _textController.text,
                  widget.transcribedText == null
                      ? 'No formatted text available'
                      : widget.transcribedText!,
                  style: GoogleFonts.karla(
                    fontSize: 16,
                    color: const Color(0xFF6E6E6E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 43,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.white),
                  child: Center(
                    child: Text(
                      "Unprocessed text as spoken to Oscar",
                      style: TextStyle(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  widget.unformattedText == null
                      ? 'No original text is provided'
                      : widget.unformattedText!,
                  style: GoogleFonts.karla(
                    fontSize: 16,
                    color: const Color(0xFF6E6E6E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: widget.transcribedText=='Listening for speech...'
          ? _buildEmptyInputBottomSheet(context)
          : _buildFullInputBottomSheet(context),
    );
  }
  
  Widget _buildEmptyInputBottomSheet(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return SafeArea(
      child: BottomAppBar(
        height: mq.height * 1 / 8,
        color: Color.fromRGBO(220, 236, 235, 1.0),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: mq.height * 0.001),
            child: Container(
              // width: mq.width*1/10,
              height: mq.height * 1 / 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: IconButton(
                    iconSize: mq.width * 1 / 12,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecordView(
                            onRecordingComplete: (String recording) {
                              // Handle recording completion here
                            },
                            tokenid: widget.tokenid,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.replay_outlined,
                      color: AppColors.ButtonColor2,
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildFullInputBottomSheet(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return SafeArea(
      child: BottomAppBar(
        height: mq.height * 1 / 9,
        color: Color.fromRGBO(220, 236, 235, 1.0),
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.height * 0.01),
          //  padding: EdgeInsets.only(top: mq.height * 0.02,bottom: mq.height * 0.01),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                height: 48,
                margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(mq.width * 0.1),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.copy, color: AppColors.ButtonColor2),
                        onPressed: _copyText,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: AppColors.ButtonColor2),
                        onPressed: _shareText,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.red),
                        onPressed: () {
                          _deleteTranscription(context);
                          // _handleDeleteTranscription();
                          Navigator.pop(context);
                        },
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: GestureDetector(
                  onTap: _sendTranscriptionToBackend,
                  child: Container(
                    // margin: EdgeInsets.symmetric(horizontal: mq.width * 0.02),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                    ),

                    // padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05,vertical: mq.height * 0.02),
                    height: 48,
                    // width: mq.width*0.03,

                    decoration: BoxDecoration(
                      color: AppColors.ButtonColor2,
                      borderRadius: BorderRadius.circular(mq.width * 0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 20,
                        ),
                        // Spacer(),
                        SizedBox(
                            width:
                                mq.width * 0.02), // Space between icon and text
                        Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

