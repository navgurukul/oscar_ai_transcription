import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:oscar_stt/ui/views/auth/login_view.dart';
import 'package:oscar_stt/ui/views/nointernet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../record/record_view.dart';
import 'dart:async';

class TranscribeResult extends StatefulWidget {
  final String transcribedText;
  final String title_text;
  final String unformattedText;
  final VoidCallback? onDelete;
  final String tokenid;
  final bool isEmptyInput;
  // final date;


  const TranscribeResult(
      {Key? key,
        required this.transcribedText,
        this.onDelete,
        required this.tokenid,
        required this.isEmptyInput,
        required this.unformattedText,
        required this.title_text,
        // required this.date
      }) : super(key: key);
  @override
  State<TranscribeResult> createState() => _TranscribeResultState();
}
class _TranscribeResultState extends State<TranscribeResult>  with SingleTickerProviderStateMixin{
  late TextEditingController _textController;
  late TextEditingController _text_titleController;
  late TextEditingController _notFormattedText;
  late TabController _tabController;
  final Connectivity _connectivity = Connectivity();
  late final Stream<ConnectivityResult> _connectivityStream;
  String? responseDate;
  String? displayedDate;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.transcribedText);
    _notFormattedText = TextEditingController(text: widget.unformattedText);
    _text_titleController = TextEditingController(text: widget.title_text);
    _tabController = TabController(length: 2, vsync: this);
    // _textController = TextEditingController(text: widget.transcribedText);
    // _notFormattedText = TextEditingController(text: widget.unformattedText);
    super.initState();
    _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
    _monitorInternet();
  }

  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // Navigate to the NoInternetScreen
        Navigator.of(context).pushReplacement(MaterialPageRoute(
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
    );}
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
          'title': _text_titleController.text ,// Added to check....
        }),
      );
   if (response.statusCode == 201) {
        print('Transcription successfully sent: ${response.statusCode}');
        final headerDate = response.headers['date'];
        if (responseDate != null) {
          displayedDate = _formatDate(responseDate!);
          setState(() {}); // Only call setState() if needed
        }
        else {
          print('Date header not found');
        }


        Navigator.pop(context, 'Saved transcription');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved transcription')),
        );
      }
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
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginView()),
                          (route) => false,
                    );
                  },
                  child: Text('OK'),),],);},);}
      else {
        print('Failed to send transcription: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during sending transcription: $e');
    }
  }
  @override
  void didUpdateWidget(covariant TranscribeResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transcribedText != oldWidget.transcribedText) {
      _textController.text = widget.transcribedText;
    }
  }
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('MMM dd, yyyy').format(date); // Formats to Jan 10, 2025
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMMM dd, yyyy').format(now);
    bool isInputEmpty = widget.unformattedText != 'Listening for speech...' ;
    // final formattedDate =
    // _formatDate(response['createdAt']);
    // final formattedDate =
    // _formatDate(transcribedText['createdAt']);
    // if (isInputEmpty){
      return 
      // Scaffold(
      //   backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      //   appBar: AppBar(
      //     scrolledUnderElevation: 0.0,
      //     automaticallyImplyLeading: false,
      //     elevation: 0,
      //     leading: IconButton(
      //         icon: Icon(Icons.arrow_back_ios, size: mq.width * 0.04),
      //         onPressed: _handleBack),
      //     backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      //     bottom: TabBar(
      //       controller: _tabController,
      //       indicatorColor: const Color(0xFF51A09B), // Custom indicator color
      //       indicatorWeight: 4.0,
      //       indicatorSize: TabBarIndicatorSize.tab,
      //       indicatorPadding: EdgeInsets.symmetric(horizontal: 20.0), // Padding
      //       labelColor: const Color(0xFF51A09B), // Active tab text color
      //       unselectedLabelColor:
      //       const Color(0xFF6E6E6E), // Inactive tab text color
      //       labelStyle: GoogleFonts.karla(
      //         fontSize: 16,
      //         fontWeight: FontWeight.w700,
      //       ),
      //       unselectedLabelStyle: GoogleFonts.karla(
      //         fontSize: 16,
      //         fontWeight: FontWeight.w700,
      //       ),
      //       tabs: [
      //         Tab(
      //           text: "Polished Text",
      //         ),
      //         Tab(text: "Original Text"),
      //       ],
      //     ),),
      //   body: TabBarView(
      //     controller: _tabController,
      //     children: [
      //       SingleChildScrollView(
      //         child: Padding(
      //           padding: const EdgeInsets.all(20.0),
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //               Text(
      //                 _text_titleController.text,
      //                 style: GoogleFonts.spectral(
      //                   fontSize: 20,
      //                   fontWeight: FontWeight.w700,
      //                   color: Color(0xFF4A4A4A),
      //                 ),
      //               ),
      //               SizedBox(
      //                 height: 5,
      //               ),
      //               // if (displayedDate != null)
      //                 // Text(
      //                 //   formattedDate,
      //                 //   style: GoogleFonts.spectral(fontSize: 16),
      //                 // ),
      //               Text(
      //                 formattedDate,
      //                 style: GoogleFonts.karla(
      //                 fontSize: 16,
      //                 color: const Color(0xFF6E6E6E),
                      
      //                 fontWeight: FontWeight.w400,
      //               ),
      //               textAlign: TextAlign.center,
      //             ),
      //               SizedBox(height: 10,),
      //               Text(
      //                 // _textController.text,
      //                 widget.transcribedText == null
      //                     ? 'No formatted text available'
      //                     : widget.transcribedText!,
      //                 style: GoogleFonts.karla(
      //                   fontSize: 16,
      //                   color: Color(0xFF4A4A4A),
      //                   fontWeight: FontWeight.w400,),),],),),
      //       ),
      //       Padding(
      //         padding: const EdgeInsets.all(20.0),
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Container(
      //               height: 43,
      //               decoration: BoxDecoration(
      //                   borderRadius: BorderRadius.all(Radius.circular(10)),
      //                   color: Colors.white),
      //               child: Center(
      //                 child: Text(
      //                   "Unprocessed text as spoken to Oscar",
      //                   style: TextStyle(
      //                       color: const Color(0xFF4A4A4A),
      //                       fontSize: 16,
      //                       fontWeight: FontWeight.w700),
      //                 ),
      //               ),
      //             ),
      //             SizedBox(
      //               height: 20,
      //             ),
      //             Text(
      //               widget.unformattedText == null
      //                   ? 'No original text is provided'
      //                   : widget.unformattedText!,
      //               style: GoogleFonts.karla(
      //                 fontSize: 16,
      //                 color: const Color(0xFF6E6E6E),
      //                 fontWeight: FontWeight.w400,),),],),),],),
      //   bottomSheet: _buildFullInputBottomSheet(context),
      // );

      Scaffold(
      backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      appBar: AppBar(
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
          indicatorSize: TabBarIndicatorSize.tab,
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
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.only(top:20.0,left: 20.0, right: 20.0,bottom: 100),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // _textController.text,
                    widget.title_text == null ? 'Untitled' : widget.title_text!,
                    style: GoogleFonts.spectral(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color:Color(0xFF4A4A4A),
                    ),
                    // textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    // _textController.text,
                    formattedDate,
                    style: GoogleFonts.karla(
                      fontSize: 16,
                      color: const Color(0xFF6E6E6E),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 10,
                  ),
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
          ),
          Padding(
            padding: const EdgeInsets.only(top:20.0,left: 20.0, right: 20.0,bottom: 100),
            child: SingleChildScrollView(
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
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // body: SafeArea(
      //   child: Padding(
      //     padding: EdgeInsets.all(mq.width * 0.04),
      //     child: SingleChildScrollView(
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         children: [
      //           Center(
      //             child: Container(
      //               constraints: BoxConstraints(
      //                 minHeight: mq.height * 0.2,
      //                 maxHeight: mq.height * 0.5,
      //                 minWidth: mq.width * 1.0,
      //                 maxWidth: mq.width * 1.0,
      //               ),
      //               decoration: BoxDecoration(
      //                 color: AppColors.ButtonColor,
      //                 border: Border.all(color: AppColors.ButtonColor),
      //                 borderRadius: BorderRadius.all(Radius.circular(20)),
      //               ),
      //               child: Padding(
      //                 padding: const EdgeInsets.all(8.0),
      //                 child: SingleChildScrollView(
      //                   child: Column(
      //                     children: [
      //                       Center(
      //                         child: Column(
      //                           children: [
      // Text(
      //   // _textController.text,
      //   widget.title == null ? '' : widget.title!,
      //   style: GoogleFonts.roboto(
      //     fontSize: mq.width * 0.05,
      //     fontWeight: FontWeight.bold,
      //   ),
      //   textAlign: TextAlign.center,
      // ),
      // Text(
      //   // _textController.text,
      //   widget.date,
      //   style: GoogleFonts.roboto(
      //     fontSize: mq.width * 0.05,
      //     fontWeight: FontWeight.bold,
      //   ),
      //   textAlign: TextAlign.center,
      // ),
      //                           ],
      //                         ),
      //                       ),
      //                       SizedBox(
      //                         height: 2,
      //                       ),
      //                       // Text(
      //                       //   // _textController.text,
      //                       //   widget.date == null ? '' : widget.date,
      //                       //   style: GoogleFonts.roboto(
      //                       //     fontSize: mq.width * 0.05,
      //                       //     fontWeight: FontWeight.w600,
      //                       //   ),
      //                       //   textAlign: TextAlign.center,
      //                       // ),
      // SizedBox(
      //   height: 5,
      // ),
      // Text(
      //   // _textController.text,
      //   widget.transcribedText == null
      //       ? 'No formatted text available'
      //       : widget.transcribedText!,
      //   style: GoogleFonts.roboto(
      //     fontSize: mq.width * 0.05,
      //     fontWeight: FontWeight.normal,
      //   ),
      //   textAlign: TextAlign.center,
      // ),
      //                     ],
      //                   ),
      //                 ),
      //               ),
      //             ),
      //           ),
      //           if (_showTranscribedText)
      //             Container(
      //               constraints: BoxConstraints(
      //                 minWidth: mq.width * 0.8,
      //                 maxWidth: mq.width * 0.8,
      //               ),
      //               decoration: BoxDecoration(
      //                 color: Colors.white,
      //                 border: Border.all(color: Colors.white),
      //                 borderRadius: BorderRadius.only(
      //                   bottomRight: Radius.circular(20),
      //                   bottomLeft: Radius.circular(20),
      //                 ),
      //               ),
      //               child: Padding(
      //                 padding: const EdgeInsets.all(8.0),
      //                 child: SingleChildScrollView(
      // child: Text(
      //   widget.unformattedText == null
      //       ? 'No original text is provided'
      //       : widget.unformattedText!,
      //   style: GoogleFonts.roboto(
      //     fontSize: mq.width * 0.05,
      //     fontWeight: FontWeight.normal,
      //   ),
      //   textAlign: TextAlign.center,
      // ),
      //                 ),
      //               ),
      //             ),
      //           Container(
      //             decoration: BoxDecoration(
      //               color: Colors.orange,
      //               border: Border.all(color: Colors.orange),
      //               borderRadius: BorderRadius.only(
      //                 bottomRight: Radius.circular(20),
      //                 bottomLeft: Radius.circular(20),
      //               ),
      //             ),
      //             child: TextButton(
      //               onPressed: () {
      //                 setState(() {
      //                   _showTranscribedText = !_showTranscribedText;
      //                 });
      //               },
      //               child: Text(
      //                 _showTranscribedText
      //                     ? 'Hide Original Transcripts'
      //                     : 'View Original Transcripts',
      //                 style: GoogleFonts.roboto(
      //                   fontSize: mq.width * 0.045,
      //                   fontWeight: FontWeight.bold,
      //                   color: Colors.white,
      //                 ),
      //               ),
      //             ),
      //           ),
      //           SizedBox(height: mq.height * 0.09),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
      bottomSheet:
          // widget.isEmptyInput
          //     ? _buildEmptyInputBottomSheet(context)
          //:
          _buildFullInputBottomSheet(context),
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
                        iconSize: 20,),],),),),
              SafeArea(
                child: GestureDetector(
                  onTap: _sendTranscriptionToBackend,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    height: 48,
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
                        SizedBox(
                            width:
                            mq.width * 0.02), // Space between icon and text
                        Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,),),],),),),),],),),),);}
  @override
  void dispose() {
    _textController.dispose();
    _notFormattedText.dispose();
    _text_titleController.dispose();
    _tabController.dispose();
    // _connectivitySubscription?.cancel();
    // _connectivitySubscription = null;
    super.dispose();
  }
}



