import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../record/record_view.dart';

class TranscribeResult extends StatefulWidget {
  final String transcribedText;
  final String unformattedText;
  final VoidCallback onDelete;
  final String tokenid;
  final bool isEmptyInput;

  const TranscribeResult(
      {Key? key,
        required this.transcribedText,
        required this.onDelete,
        required this.tokenid,
        this.isEmptyInput = false,
        required this.unformattedText})
      : super(key: key);

  @override
  State<TranscribeResult> createState() => _TranscribeResultState();
}

class _TranscribeResultState extends State<TranscribeResult> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late TextEditingController _notFormattedText;
  bool _showTranscribedText = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.transcribedText);
    _notFormattedText = TextEditingController(text: widget.unformattedText);
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
    widget.onDelete(); // Perform the delete operation
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
    final String apiUrl =
        'https://dev-oscar.merakilearn.org/api/v1/transcriptions/add'; // Replace with your actual API URL
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
        }),
      );
      if (response.statusCode == 201) {
        print('Transcription successfully sent: ${response.statusCode}');
        Navigator.pop(context, 'Saved transcription');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved transcription')),
        );
      } else {
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
        title: Center(
          child: Text(
            'Your transcription!',
            style: TextStyle(fontSize: mq.width * 0.05,fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
        toolbarHeight: mq.height * 0.1,
      ),
      // body: SafeArea(
      //   child: Padding(
      //     padding: EdgeInsets.all(mq.width * 0.04),
      //     child: SingleChildScrollView(
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         // mainAxisAlignment: MainAxisAlignment.center,
      //         children: [
      //           Center(
      //             child: Container(
      //               constraints: BoxConstraints(
      //               minHeight: mq.height * 0.2,
      //                 maxHeight: mq.height * 0.5,
      //                 minWidth: mq.width * 1.0,
      //                 maxWidth: mq.width * 1.0,
      //             ),
      //               decoration:
      //                   BoxDecoration(
      //                       color: AppColors.ButtonColor,
      //                       border: Border.all(color: AppColors.ButtonColor),
      //                       borderRadius: BorderRadius.all(Radius.circular(20))
      //                   ),
      //               child: Padding(
      //                 padding: const EdgeInsets.all(8.0),
      //                 child: Expanded(
      //                   child: SingleChildScrollView(
      //                     child: Text(
      //                       _textController.text,
      //                       // _showTranscribedText ? widget.unformattedText : _textController.text,
      //                       style: GoogleFonts.roboto(
      //                         fontSize: mq.width * 0.05,
      //                         fontWeight: FontWeight.normal,
      //                       ),
      //                       textAlign: TextAlign.center,
      //                     ),
      //                   ),
      //                 ),
      //               ),
      //             ),
      //           ),
      //
      //           if (_showTranscribedText)
      //             Container(
      //               constraints: BoxConstraints(
      //               //
      //                 minWidth: mq.width * 0.8,
      //                 maxWidth: mq.width * 0.8,
      //               ),
      //               decoration: BoxDecoration(color: Colors.white,
      //                 border: Border.all(color: Colors.white),
      //                   borderRadius: BorderRadius.only(bottomRight:Radius.circular(20), bottomLeft: Radius.circular(20) )
      //
      //               ),
      //               child: Padding(
      //                 padding: const EdgeInsets.all(8.0),
      //                 child:
      //                  Expanded(
      //                    child: SingleChildScrollView(
      //                     child: Text(
      //                       widget.unformattedText,
      //                       style: GoogleFonts.roboto(
      //                         fontSize: mq.width * 0.05,
      //                         fontWeight: FontWeight.normal,
      //                       ),
      //                       textAlign: TextAlign.center,
      //
      //                     ),
      //                                          ),
      //                  ),
      //               ),
      //             ),
      //           Container(
      //             decoration: BoxDecoration(
      //                 color: Colors.orange,
      //                 border: Border.all(color: Colors.orange),
      //                 borderRadius: BorderRadius.only(bottomRight:Radius.circular(20), bottomLeft: Radius.circular(20) )
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
      //                   color: Colors.white
      //                 ),
      //               ),
      //             ),
      //           ),
      //
      //
      //
      //           SizedBox(height: mq.height * 0.09),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(mq.width * 0.04),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: mq.height * 0.2,
                      maxHeight: mq.height * 0.5,
                      minWidth: mq.width * 1.0,
                      maxWidth: mq.width * 1.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ButtonColor,
                      border: Border.all(color: AppColors.ButtonColor),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Text(
                          _textController.text,
                          style: GoogleFonts.roboto(
                            fontSize: mq.width * 0.05,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_showTranscribedText)
                  Container(
                    constraints: BoxConstraints(
                      minWidth: mq.width * 0.8,
                      maxWidth: mq.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.unformattedText,
                          style: GoogleFonts.roboto(
                            fontSize: mq.width * 0.05,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showTranscribedText = !_showTranscribedText;
                      });
                    },
                    child: Text(
                      _showTranscribedText
                          ? 'Hide Original Transcripts'
                          : 'View Original Transcripts',
                      style: GoogleFonts.roboto(
                        fontSize: mq.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.09),
              ],
            ),
          ),
        ),
      ),


      bottomSheet: widget.isEmptyInput
          ? _buildEmptyInputBottomSheet(context)
          : _buildFullInputBottomSheet(context),
    );
  }

  Widget _buildEmptyInputBottomSheet(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return BottomAppBar(
      color: Color.fromRGBO(220, 236, 235, 1.0),
      child: Container(
        color: Color.fromRGBO(220, 236, 235, 1.0),
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.height * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
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
                child: Image.asset('assets1/Frame 24.png',
                    width: mq.width * 0.15 // Adjust the height if necessary
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullInputBottomSheet(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return SafeArea(
      child: BottomAppBar(
        color: Color.fromRGBO(220, 236, 235, 1.0),
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.height * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(mq.width * 0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.copy, color: AppColors.ButtonColor2),
                      onPressed: _copyText,
                      iconSize: mq.width * 0.07,
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: AppColors.ButtonColor2),
                      onPressed: _shareText,
                      iconSize: mq.width * 0.07,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppColors.ButtonColor2),
                      onPressed: () {
                        _deleteTranscription(context);
                        // _handleDeleteTranscription();
                        Navigator.pop(context);
                      },
                      iconSize: mq.width * 0.07,
                    ),

                  ],
                ),
              ),

              SafeArea(
                child: GestureDetector(
                  onTap: _sendTranscriptionToBackend,
                  child: Container(
                    // margin: EdgeInsets.symmetric(horizontal: mq.width * 0.02),
                    padding: EdgeInsets.symmetric(
                      horizontal: mq.width * 0.05,
                    ),

                    // padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05,vertical: mq.height * 0.02),
                    height: mq.height * 0.07,
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
                          size: mq.width * 0.06,
                        ),
                        // Spacer(),
                        SizedBox(
                            width:
                            mq.width * 0.02), // Space between icon and text
                        Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: mq.width * 0.04,
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
