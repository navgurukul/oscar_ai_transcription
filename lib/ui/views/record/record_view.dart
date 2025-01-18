// Correct code without solving crash but having open ai integration here:
// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:oscar_stt/ui/views/auth/login_view.dart';
// import 'package:oscar_stt/ui/views/home/home_view.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:oscar_stt/core/constants/app_colors.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:path_provider/path_provider.dart';
// import '../../../core/constants/app_colors.dart';
// import '../transcribe/transcribe_view.dart';
// import 'package:http/http.dart' as http;

// class RecordView extends StatefulWidget {
//   final Function(String) onRecordingComplete;
//   final String tokenid;

//   RecordView({required this.onRecordingComplete,required this.tokenid});

//   @override
//   _RecordViewState createState() => _RecordViewState();
// }

// class _RecordViewState extends State<RecordView> {
//   late stt.SpeechToText _speech;
//   String _speechText = '';
//   Timer? _timer;
//   bool _isRecording = false;
//   int _seconds = 0;
//   bool _isDiscardButtonActive = false;
//   bool _isKeepRecordingButtonActive = true;
//   bool _isRestarted = false;
//   bool _isPaused = false;
//   bool _isLoading = false;

//   String _completeSpeechText = '';

//   // late final GenerativeModel _model;
//   // final String geminiApiUrl =
//   //     "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=AIzaSyD2-74-Ol3Yw29b0aG31o9yUnukrW2aHqo"; // Replace with your API key

//   // final Map<String, String> headers = {'Content-Type': 'application/json'};

//   @override
//   void initState() {
//     super.initState();
//     // _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'AIzaSyD2-74-Ol3Yw29b0aG31o9yUnukrW2aHqo'); // Replace 'YOUR_API_KEY' with your actual API key
//     _initializeSpeechToText();
//     _startRecording();
//   }

//   void _startTimer() {
//     // _isPaused = false;
//     _timer = Timer.periodic(Duration(seconds: 1), ( Timer timer) {
//       setState(() {
//         _seconds++;
//       });
//     });
//   }

//   void _pauseTimer() {
//     // _isPaused = true;
//     _timer?.cancel();
//   }

//   void _resumeTimer() {
//     if (!_isPaused) return;
//     _isPaused = false;
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       setState(() {
//       });
//     });
//   }

//   void _showRestartAlert() {
//     _pauseTimer(); // Pause the timer when the alert is shown

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.0), // Square shape with slightly rounded corners
//           ),
//           title: Text(
//             'Reset the Recording',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           content: Text(
//             'Resetting the recording will erase the current audio note and start a new one.',
//             style: TextStyle(
//               color: Colors.black,
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _restartRecordingSession();
//               },
//               child: Text(
//                 'Reset',
//                 style: TextStyle(color: AppColors.ButtonColor2),
//               ),
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all(Colors.white),
//                 side: WidgetStateProperty.all(BorderSide(color: AppColors.ButtonColor2)),
//                 padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _resumeTimer(); // Resume the timer if it was paused
//               },
//               child: Text(
//                 'Close',
//                 style: TextStyle(color: Colors.white),
//               ),
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all(AppColors.ButtonColor2),
//                 padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//             ),
//           ],
//         );
//       },
//     ).then((_) {
//       _resumeTimer();
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   bool _isDialogOpen = false;

//   // Future<String?> _formatText(String originalText) async {
//   //   setState(() {
//   //     _isLoading = true; // Start loading
//   //   });

//   //   try {
//   //     final content = [
//   //       Content.text(
//   //           "Please take the following voice input, neutralize any harmful, sexual, or offensive language if present, and translate the input into English if necessary. Return only the polite, rephrased English version of the text without adding any extra comments, explanations, or alternative responses. Original input: $originalText"
//   //       )

//   //     ];
//   //     final response = await _model.generateContent(content);

//   //     print("API Response: ${response.text}");

//   //     if (response.text == null || response.text!.isEmpty) {
//   //       print("Generated text was blocked or empty.");
//   //       return originalText; // Return the original text if the generated one is blocked
//   //     }

//   //     // Extract only the formatted text from the response
//   //     final formattedText = _extractFormattedText(response.text!);

//   //     // Return the original text if formatted text is empty or identical to the original
//   //     return formattedText.isEmpty || formattedText == originalText
//   //         ? originalText
//   //         : formattedText;
//   //   } catch (e) {
//   //     print("Error using Gemini API: $e");
//   //     if (!_isDialogOpen) {
//   //       _isDialogOpen = true; // Mark dialog as open
//   //       showDialog(
//   //         context: context,
//   //         barrierDismissible:
//   //             false, // Prevent dialog from closing on tap outside
//   //         builder: (BuildContext context) {
//   //           return AlertDialog(
//   //             title: Text('Oops ! An error occured'),
//   //             content: Text('$e'),
//   //             actions: [
//   //               TextButton(
//   //                 onPressed: () async {
//   //                    _isDialogOpen = false; // Mark dialog as closed
//   //                     Navigator.of(context).pop();
//   //                     Navigator.of(context).pop();
//   //                    // Close the dialog

//   //                   // Navigate to LoginView
//   //                   // Navigator.of(context).pushAndRemoveUntil(
//   //                   //   MaterialPageRoute(builder: (context) => HomePage()),
//   //                   //   (route) => false,
//   //                   // );
//   //                 },
//   //                 child: Text('OK'),
//   //               ),
//   //             ],
//   //           );
//   //         },
//   //       );};
//   //     // return originalText; // Return the original text if an error occurs
//   //   } finally {
//   //     setState(() {
//   //       _isLoading = false; // End loading
//   //     });
//   //   }
//   // }

// Future<String?> _formatText(String _speechText) async {
//   var mq = MediaQuery.of(context).size;
//   setState(() {
//     _isLoading = true; // Start loading
//     // _isDialogOpen = false;
//   });

//   const String apiUrl = "https://dev-oscar.merakilearn.org/api/v1/optimize/optimize-text"; // Replace with your API endpoint

//   try {
//     // Prepare the POST request body
//     final Map<String, String> body = {

//       "user_input": _speechText,
//       "device_tag": '3',
//     };

//     // Make the POST request
//     final response = await http.post(
//       Uri.parse(apiUrl),
//       headers: {
//         'Authorization': 'Bearer ${widget.tokenid}',
//         'Content-Type': 'application/json; charset=UTF-8'
//       },
//       body: jsonEncode(body),
//     );

//     // Check the status code
//     if (response.statusCode == 201) {
//       print('Transcription successfull ');

//       final responseData = jsonDecode(response.body);

//       // Extract formatted text from response
//       final formattedText = responseData["data"]["output"] ?? _speechText;

//       return formattedText.isEmpty || formattedText == _speechText
//           ? _speechText
//           : formattedText;

//     }else if (response.statusCode == 401) {
//       print('Unauthorized');
//       // final responseData = jsonDecode(response.body);
//       // _showErrorDialog(context ,'Your token is expired , Please login again'  );
//        // Show AlertDialog
//         showDialog(
//           context: context,
//           barrierDismissible:
//               false, // Prevent dialog from closing on tap outside
//           builder: (BuildContext context) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.0), // Square shape with slightly rounded corners
//           ),
//               title: Text('Session Expired', style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),),
//               content: Text('Your token is expired and you will now be logged out . Please Login again', style: TextStyle(
//               fontWeight: FontWeight.w400,fontSize: mq.width * 0.04,
//               color: Colors.black,
//             ),),
//               actions: [
//                 TextButton(
//                   onPressed: () async {
//                     // Navigator.of(context).pop(); // Close the dialog

//                     // Sign out and clear session
//                     await GoogleSignIn().signOut();
//                     SharedPreferences prefs =
//                         await SharedPreferences.getInstance();
//                     await prefs.remove('isLoggedIn');

//                     // Navigate to LoginView
//                     Navigator.of(context).pushAndRemoveUntil(
//                       MaterialPageRoute(builder: (context) => LoginView()),
//                       (route) => false,
//                     );
//                   },
//                   child: Text('OK',style: TextStyle(color: Colors.white),), style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all(AppColors.ButtonColor2),
//                 padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//                 ),
//               ],
//             );
//           },
//         );

//     }else if (response.statusCode == 429) {
//       print('To many request or daily quota exceed');
//       _showErrorDialog(context ,'To many request or daily quota exceed');

//     }else if (response.statusCode == 500) {
//       print('Internal Server Error.');
//       _showErrorDialog(context ,'The server had an error while processing your request');
//     }

//     else {

//       print("Error: ${response.statusCode} - ${response.body}");
//       final responseData = jsonDecode(response.body);
//       // _showErrorDialog(context ,responseData['message']);

//       return responseData['message']; // Return the "message"
//     }
//   } catch (e) {
//     // Handle exceptions
//     print("Error making POST request: $e");
//     _showErrorDialog(context , e as String);
//     // return _speechText;
//   } finally {
//     setState(() {
//       _isLoading = false; // End loading
//     });
//   }
// }

// void _showErrorDialog(BuildContext context, String errorMessage) {
//   var mq = MediaQuery.of(context).size;
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dialog from closing on outside tap
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.0), // Square shape with slightly rounded corners
//           ),
//           title: const Text('Oops an error occured',style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),),
//           content: Text(errorMessage,style: TextStyle(
//               fontWeight: FontWeight.w400,fontSize: mq.width * 0.04,
//               color: Colors.black,
//             ),), // Display error message dynamically
//           actions: [
//             TextButton(
//               // onPressed: () {
//               //   _isDialogOpen = false; // Mark dialog as closed
//               //   Navigator.of(context).pop(); // Close the dialog
//               // },
//               onPressed: ()async {
//                 // _isDialogOpen = false; // Mark dialog as closed
//                 // Navigator.of(context).pop(); // Close the dialog
//                 Navigator.of(context).pop();
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 String profileName = prefs.getString('profileName') ?? '';
//                 String profilePicUrl = prefs.getString('profilePicUrl') ?? '';
//                 String transcribedata = prefs.getString('transcribedata') ?? '';
//                 Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => HomePage(
//             profileName: profileName,
//             profilePicUrl: profilePicUrl,
//             transcribedata: transcribedata,
//             tokenid: widget.tokenid,
//           ),
//         ),
//       );
//               },
//               child: const Text('OK',style: TextStyle(color: Colors.white),),
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all(AppColors.ButtonColor2),
//                 padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // String _extractFormattedText(String apiResponse) {
//   //   final formattedTextPattern = RegExp(r'The sentence \"(.*?)\" is grammatically correct\.', caseSensitive: false);

//   //   final match = formattedTextPattern.firstMatch(apiResponse);
//   //   if (match != null && match.group(1) != null) {
//   //     // Extract the text within the double quotes
//   //     return match.group(1)!.trim();
//   //   }

//   //   // Return the original response if no specific pattern is found
//   //   return apiResponse.trim();
//   // }

//   bool _hasTranscriptionBeenSent = false;
//   bool _isProcessing = false;

//   Future<void> _stopCurrentRecording({bool isRestarting = false}) async {
//     if (!_isRecording) return; // Avoid multiple stops

//     setState(() {
//       _isRecording = false;

//     });

//     _timer?.cancel(); // Stop the timer

//     // Stop the speech recognition
//     await _speech.stop();
//     bool isEmptyInput = _speechText.isEmpty;

//     if (!isRestarting && !_hasTranscriptionBeenSent) {
//       String textToSend;
//       if (_speechText.isNotEmpty) {
//         // Checking if formatting is needed
//         final bool needsFormatting = _checkIfFormattingNeeded(_speechText);

//         String? formattedText = needsFormatting ? await _formatText(_speechText) : _speechText;

//         if (formattedText != null) {
//           // await _sendTranscriptionToBackend(formattedText);
//           _hasTranscriptionBeenSent = true; // Mark as sent

//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => TranscribeResult(
//                 transcribedText: formattedText,
//                 unformattedText: _speechText,
//                 isEmptyInput: isEmptyInput,
//                 onDelete: () {
//                   widget.onRecordingComplete('');
//                   _hasTranscriptionBeenSent = false; // Reset flag on deletion
//                 },
//                 tokenid: widget.tokenid,
//               ),
//             ),
//           );
//         } else {
//           print('No formatted text available.');
//         }
//       } else {
//         print("Not available");

//       }
//     }

//   }

//   Future<void> _stopRecording() async {
//     await _stopCurrentRecording();

//     try {
//       final transcriptionToSend = _isRestarted ? _speechText : _speechText;
//       bool isEmptyInput = transcriptionToSend.isEmpty;

//       if (!_hasTranscriptionBeenSent) {
//         String? formattedText = await _formatText(transcriptionToSend);

//         if (formattedText != null) {
//           // await _sendTranscriptionToBackend(formattedText);
//           _isRestarted = false;

//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => TranscribeResult(
//                 transcribedText: formattedText,
//                 unformattedText: _speechText,
//                 isEmptyInput: isEmptyInput,
//                 onDelete: () {
//                   widget.onRecordingComplete('');
//                   _hasTranscriptionBeenSent = false; // Reset flag on deletion
//                 },
//                 tokenid: widget.tokenid,
//               ),
//             ),
//           );
//         } else {
//           print('No formatted text available.');
//         }
//       }
//     } catch (e) {
//       print('Error stopping the recording: $e');
//     }
//   }

//   void _initializeSpeechToText() {
//     _speech = stt.SpeechToText();
//     _checkPermissionAndStartListening();
//   }

//   void _restartRecordingSession() async {
//     await _stopCurrentRecording(isRestarting: true);

//     setState(() {
//       _isRestarted = true;
//       _seconds = 0;
//       _speechText = '';// Reset timer
//     });

//     _initializeSpeechToText();

//     _startRecording(); // Start a new recording session
//   }

//   //Use later................................
//   // Future<void> _resumeRecording() async {
//   //   if (_isPaused) {
//   //     setState(() {
//   //       _isPaused = false;
//   //     });
//   //     _startTimer();
//   //     _speech.listen(onResult: (val) {
//   //       setState(() {
//   //         _speechText = val.recognizedWords;
//   //       });
//   //       if (val.finalResult) {
//   //         print('Final speech result: $_speechText');
//   //       }
//   //     });
//   //   }
//   // }

//   Future<void> _startRecording() async {
//     setState(() {
//       _isRecording = true;
//       _seconds = 0;
//     });
//     _startTimer();

//     // Initialized the speech recognition and start listening with the specified parameters
//     await _speech.listen(
//       onResult: (val) {
//         setState(() {
//           // _speechText = val.recognizedWords;

//           if (val.finalResult) {
//             _completeSpeechText += ' ' + val.recognizedWords;
//             print('Appended text: $_completeSpeechText');
//           }
//         });
//         // if (val.finalResult) {
//         //   print('Final speech result: $_speechText');
//         // }
//       },
//       listenFor: Duration(minutes: 3), //  maximum listening duration to 1 minute
//       pauseFor: Duration(minutes: 20),  //  the time allowed for silence before stopping to 1 minute
//       onSoundLevelChange: (level) {
//         _stopCurrentRecording();
//         _startRecording();
//       },
//     );
//   }

//   bool _checkIfFormattingNeeded(String text) {
//     return true;
//   }

//   String _formatTime(int seconds) {
//     final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
//     final secs = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$secs';
//   }

//   void _checkPermissionAndStartListening() async {
//     bool available = await _speech.initialize(
//       onStatus: (val) => print('onStatus: $val'),
//       onError: (val) {
//         print('onError: $val');
//         if (val.errorMsg == 'error_speech_timeout') {
//           print('Speech recognition timeout');
//         }
//       },
//     );

//     if (available) {
//       _speech.listen(onResult: (val) {
//         setState(() {
//           _speechText = val.recognizedWords;
//         });
//         if (val.finalResult) {
//           print('Final speech result: $_speechText');
//         }
//       });
//     }
//     else {
//       print('Speech recognition not available');
//     }

//   }

//   void _showAlertBox() {
//     setState(() {
//       _isKeepRecordingButtonActive = true;
//       _isDiscardButtonActive = false;
//     });

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         var mq = MediaQuery.of(context).size;
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.zero,),
//           title: Text(
//             'Sure you want to exit?',
//             style: TextStyle(
//               fontSize: mq.width * 0.05,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           content: Text(
//             'You are exiting the recording. Recorded data will be lost.',
//             style: TextStyle(
//               fontSize: mq.width * 0.04,
//             ),
//           ),
//           actions: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 Expanded(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 8.0),
//                     child: TextButton(
//                       onPressed: () {
//                         setState(() {
//                           _isDiscardButtonActive = true;
//                           _isKeepRecordingButtonActive = false;
//                         });
//                         Navigator.of(context).pop();
//                         Navigator.of(context).pop();
//                       },
//                       child: Text('Discard'),
//                       style: TextButton.styleFrom(
//                         foregroundColor: _isDiscardButtonActive
//                             ? Colors.white
//                             : AppColors.ButtonColor2,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                           side: BorderSide(color: AppColors.ButtonColor2),
//                         ),
//                         backgroundColor: _isDiscardButtonActive
//                             ? AppColors.ButtonColor2
//                             : Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//                 TextButton(
//                   child: Text('Start new Recording'),
//                   onPressed: () {
//                     setState(() {
//                       // Add _restartRecordingSession() this function for start recording for starting for solving bug related to arrow back button not working properly
//                       _restartRecordingSession();
//                       // _isKeepRecordingButtonActive = true;
//                       // commented this above line for solving line 475 issue of arrow back button not working
//                       // _restartRecordingSession();
//                     });
//                     Navigator.of(context).pop();
//                   },
//                   style: TextButton.styleFrom(
//                     foregroundColor: _isKeepRecordingButtonActive
//                         ? Colors.white
//                         : AppColors.ButtonColor,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       side: BorderSide(color: AppColors.ButtonColor2),
//                     ),
//                     backgroundColor: _isKeepRecordingButtonActive
//                         ? AppColors.ButtonColor2
//                         : Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),

//       appBar: AppBar(
//         backgroundColor: Colors.transparent,

//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios),
//           onPressed: () {
//             _showAlertBox();
//           },
//         ),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (_isProcessing) // Show LinearProgressIndicator when processing
//             Padding(
//               padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
//               child: LinearProgressIndicator(),
//             ),
//           Center(
//             child: Padding(
//               padding: EdgeInsets.all(mq.width * 0.025),
//               child: Container(
//                 width: double.infinity,
//                 height: mq.height * 0.2,
//                 decoration: BoxDecoration(
//                   color: AppColors.ButtonColor,
//                   // color: Colors.red,
//                   borderRadius: BorderRadius.all(
//                     Radius.circular(mq.width * 0.03),
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       _isRecording ? _formatTime(_seconds) : "00:00",
//                       style: TextStyle(
//                         fontSize: mq.width * 0.06,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),
//                     SizedBox(height: mq.height * 0.015),
//                     Image.asset(
//                       'assets1/audioWave.gif',
//                       fit: BoxFit.cover,
//                       height: mq.height * 0.12,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: mq.height * 0.1),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [

//               Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.ButtonColor2, // Red background color
//                   shape: BoxShape.circle, // Circular shape
//                 ),
//                 padding: EdgeInsets.all(mq.width * 0.02), // Padding for the icon inside the circle
//                 child: IconButton(
//                   icon: Icon(
//                     Icons.restart_alt, // Restart icon
//                     color: Colors.white, // Icon color (white for visibility)
//                   ),
//                   iconSize: mq.width * 0.08, // Responsive icon size

//                   onPressed: () {
//                     if (_isRecording) {
//                       _showRestartAlert();
//                     }
//                   },
//                 ),
//               ),

//               // Stop IconButton in a Circular Red Container
//               Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.ButtonColor2, // Red background color
//                   shape: BoxShape.circle, // Circular shape
//                 ),
//                 padding: EdgeInsets.all(mq.width * 0.02), // Padding for the icon inside the circle
//                 child: IconButton(
//                   icon: Icon(
//                     Icons.stop, // Stop icon
//                     color: Colors.white, // Icon color (white for visibility)
//                   ),
//                   iconSize: mq.width * 0.08, // Responsive icon size
//                   onPressed: _stopRecording,
//                 ),
//               ),
//               // GestureDetector(
//               //   onTap:
//               //       () {
//               //     if (_isRecording) {
//               //       // _showRestartConfirmationDialog();
//               //       // _restartRecordingSession();
//               //       _showRestartAlert();
//               //     }
//               //   },
//               //   child:
//               //
//               //
//               //   Image.asset(
//               //     'assets1/Frame 24.png',
//               //     width: mq.width * 0.15,
//               //   ),
//               // ),
//               // GestureDetector(
//               //   onTap: _stopRecording,
//               //   child: Image.asset(
//               //     'assets1/Vector.png',
//               //     width: mq.width * 0.15,
//               //   ),
//               // ),
//             ],
//           ),
//           if (_isLoading)

//           // Show loading indicator if _isLoading is true
//             if (_isLoading)
//               Stack(
//                 children: [
//                   // Blurred background
//                   BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Can adjust the blur strength as needed
//                     child: Container(
//                       color: Colors.black.withOpacity(0.2), // Slightly tinted background to improve readability
//                     ),
//                   ),
//                   // Custom loading UI
//                   Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: mq.width * 0.04, vertical: mq.height * 0.1),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [

//                           SizedBox(height: mq.height * 0.03),
//                           LinearProgressIndicator(
//                             color: Color.fromRGBO(81, 160, 155, 1.0),
//                             backgroundColor: Colors.grey[200],
//                             minHeight: 30,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           SizedBox(height: mq.height * 0.03),
//                           Padding(
//                             padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
//                             child: Text(
//                               'Please wait a moment while we prepare the text for you',
//                               style: TextStyle(
//                                 fontSize: mq.width * 0.04,
//                                 fontWeight: FontWeight.normal,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//         ],
//       ),
//     );
//   }
// }

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// code for open ai backend integration of meraki swagger api and solve crash issues's well
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:keep_screen_on/keep_screen_on.dart';
// import 'package:oscar_stt/routetrack.dart';
import 'package:oscar_stt/ui/views/auth/login_view.dart';
import 'package:oscar_stt/ui/views/home/home_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../transcribe/transcribe_view.dart';
// import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

class RecordView extends StatefulWidget {
  final Function(String) onRecordingComplete;
  final String tokenid;

  RecordView({required this.onRecordingComplete, required this.tokenid});

  @override
  _RecordViewState createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> {
  late stt.SpeechToText _speech;
  String _speechText = '';
  Timer? _timer;
  bool _isRecording = false;
  int _seconds = 0;
  bool _isDiscardButtonActive = false;
  bool _isKeepRecordingButtonActive = true;
  bool _isRestarted = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isDialogOpen = false;
  String _completeSpeechText = '';

  // late final GenerativeModel _model;
  // final String geminiApiUrl =
  // "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=AIzaSyD2-74-Ol3Yw29b0aG31o9yUnukrW2aHqo"; // Replace with your API key

  // final Map<String, String> headers = {'Content-Type': 'application/json'};

  @override
  void initState() {
    super.initState();
    // _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'AIzaSyC38CssFffXTiFIRZeBFp14mnbLpWliK7g'); // Replace 'YOUR_API_KEY' with your actual API key
    _initializeSpeechToText();
    // _startRecording();
  }

  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  void _initializeSpeechToText() async {
    _speech = stt.SpeechToText();
    bool micPermission = await _requestMicrophonePermission();
    if (!micPermission) {
      print('Microphone permission not granted');
      return;
    }

    try {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) {
          print('onError: $val');
          if (val.errorMsg == 'error_speech_timeout') {
            print('Speech recognition timeout');
          }
        },
      );

      if (available) {
        _speech.listen(onResult: (val) {
          setState(() {
            _speechText = val.recognizedWords;
          });
          if (val.finalResult) {
            print('Final speech result: $_speechText');
            print('allowed to record voice');
          }
        });
      } else {
        print('Speech recognition not available');
        throw Exception('Speech recognition not available.');
      }
    } on PlatformException catch (e) {
      print('PlatformException: ${e.message}');
      // Show a user-friendly message
      _showErrorDialog1('Speech recognition not available on this device.');
    } catch (e, stackTrace) {
      print('Error during SpeechToText initialization: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      _showErrorDialog1(
          'Speech recognition initialization failed. Please try again.');
    }
  }

  void _restartRecordingSession() {
    // if we comment below  _stopCurrentRecording function then old recording will not be visible or save only new will be saved .
    _stopCurrentRecording(isRestarting: true);

    setState(() {
      _isRestarted = true;
      _seconds = 0;
      _speechText = ''; // Reset timer
    });

    try {
      _initializeSpeechToText();

      _startRecording();
    } catch (e, stackTrace) {
      print('Error during restart: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      _showErrorDialog1('Failed to restart recording. Please try again.');
    } // Start a new recording session
  }

  void _startTimer() {
    // _isPaused = false;
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    // _isPaused = true;
    _timer?.cancel();
  }

  void _resumeTimer() {
    if (!_isPaused) return;
    _isPaused = false;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void _showRestartAlert() {
    _pauseTimer(); // Pause the timer when the alert is shown

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                8.0), // Square shape with slightly rounded corners
          ),
          title: Text(
            'Reset the Recording',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Resetting the recording will erase the current audio note and start a new one.',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartRecordingSession();
              },
              child: Text(
                'Reset',
                style: TextStyle(color: AppColors.ButtonColor2),
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(
                    BorderSide(color: AppColors.ButtonColor2)),
                padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeTimer(); // Resume the timer if it was paused
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(AppColors.ButtonColor2),
                padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      _resumeTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> _formatText(String _speechText) async {
    setState(() {
      _isLoading = true; // Start loading
      // _isDialogOpen = false;
    });

    const String apiUrl =
        "https://dev-oscar.merakilearn.org/api/v1/optimize/optimize-text"; // Replace with your API endpoint

    try {
      // Prepare the POST request body
      final Map<String, String> body = {
        "user_input": _speechText,
        "device_tag": '3',
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${widget.tokenid}',
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(body),
      );

      // Check the status code
      if (response.statusCode == 201) {
        print('successfull');
        final responseData = jsonDecode(response.body);
        print("Response Body: $responseData");

        // Extract formatted text from response
        final formattedText = responseData["data"]["output"] ?? _speechText;

        return formattedText.isEmpty || formattedText == _speechText
            ? _speechText
            : formattedText;
      } else if (response.statusCode == 401) {
        print('Unauthorized');
        // final responseData = jsonDecode(response.body);
        // _showErrorDialog(context ,'Your token is expired , Please login again'  );
        // Show AlertDialog
        showDialog(
          context: context,
          barrierDismissible:
              false, // Prevent dialog from closing on tap outside
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    8.0), // Square shape with slightly rounded corners
              ),
              title: Text(
                'Session Expired',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: Text(
                'Your token is expired and you are logged out.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Navigator.of(context).pop(); // Close the dialog

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
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(AppColors.ButtonColor2),
                    padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
                  ),
                ),
              ],
            );
          },
        );
      } else if (response.statusCode == 429) {
        print('To many request or daily quota exceed');
        _showErrorDialog(context, 'To many request or daily quota exceed');
      } else if (response.statusCode == 500) {
        print('Internal Server Error.');
        _showErrorDialog(
            context, 'The server had an error while processing your request');
      } else {
        // Handle API response errors
        print("Error: ${response.statusCode} - ${response.body}");
        final responseData = jsonDecode(response.body);
        // _showErrorDialog(context ,responseData['message']);

        return responseData['message']; // Return the "message"
      }
    } catch (e) {
      // Handle exceptions
      print("Error making POST request: $e");
      _showErrorDialog(context, e as String);
      // return _speechText;
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                8.0), // Square shape with slightly rounded corners
          ),
          title: const Text(
            'Oops! an error occured',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            errorMessage,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ), // Display error message dynamically
          actions: [
            TextButton(
              onPressed: () async {
                // _isDialogOpen = false; // Mark dialog as closed
                // Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String profileName = prefs.getString('profileName') ?? '';
                String profilePicUrl = prefs.getString('profilePicUrl') ?? '';
                String transcribedata = prefs.getString('transcribedata') ?? '';
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      profileName: profileName,
                      profilePicUrl: profilePicUrl,
                      transcribedata: transcribedata,
                      tokenid: widget.tokenid,
                    ),
                  ),
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(AppColors.ButtonColor2),
                padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _hasTranscriptionBeenSent = false;
  bool _isProcessing = false;

  Future<void> _stopCurrentRecording({bool isRestarting = false}) async {
    if (!_isRecording) return; // Avoid multiple stops

    setState(() {
      _isRecording = false;
    });

    _timer?.cancel(); // Stop the timer

    // Stop the speech recognition
    await _speech.stop();
    bool isEmptyInput = _speechText.isEmpty;

    if (!isRestarting && !_hasTranscriptionBeenSent) {
      String textToSend;
      if (_speechText.isNotEmpty) {
        // Checking if formatting is needed
        final bool needsFormatting = _checkIfFormattingNeeded(_speechText);

        String? formattedText =
            needsFormatting ? await _formatText(_speechText) : _speechText;

        if (formattedText != null) {
          // await _sendTranscriptionToBackend(formattedText);
          _hasTranscriptionBeenSent = true; // Mark as sent
          // context.read<NavigationState>().updateLastScreen('/transcribe');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TranscribeResult(
                transcribedText: formattedText,
                unformattedText: _speechText,
                isEmptyInput: isEmptyInput,
                onDelete: () {
                  widget.onRecordingComplete('');
                  _hasTranscriptionBeenSent = false; // Reset flag on deletion
                },
                tokenid: widget.tokenid,
              ),
            ),
          );
        } else {
          print('No formatted text available.');
        }
      } else {
        print("Not available");
      }
    }
  }

  Future<void> _stopRecording() async {
    await _stopCurrentRecording();

    try {
      final transcriptionToSend = _isRestarted ? _speechText : _speechText;
      bool isEmptyInput = transcriptionToSend.isEmpty;

      if (!_hasTranscriptionBeenSent) {
        String? formattedText = await _formatText(transcriptionToSend);

        if (formattedText != null) {
          // await _sendTranscriptionToBackend(formattedText);
          _isRestarted = false;
          // context.read<NavigationState>().updateLastScreen('/transcribe');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TranscribeResult(
                transcribedText: formattedText,
                unformattedText: _speechText,
                isEmptyInput: isEmptyInput,
                onDelete: () {
                  widget.onRecordingComplete('');
                  _hasTranscriptionBeenSent = false; // Reset flag on deletion
                },
                tokenid: widget.tokenid,
              ),
            ),
          );
        } else {
          print('No formatted text available.');
        }
      }
    } catch (e) {
      print('Error stopping the recording: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_speech == null || !_speech.isAvailable) {
      print('SpeechToText is not initialized or unavailable.');
      _showErrorDialog1(
          'Speech recognition is not initialized. Please try restarting the app.');
      return;
    }
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });
    _startTimer();

    // Initialized the speech recognition and start listening with the specified parameters
    try {
      await _speech.listen(
        onResult: (val) {
          setState(() {
            // _speechText = val.recognizedWords;

            if (val.finalResult) {
              _completeSpeechText += ' ' + val.recognizedWords;
              print('Appended text: $_completeSpeechText');
            }
          });
          // if (val.finalResult) {
          //   print('Final speech result: $_speechText');
          // }
        },
        listenFor:
            Duration(minutes: 3), //  maximum listening duration to 1 minute
        pauseFor: Duration(
            minutes:
                20), //  the time allowed for silence before stopping to 1 minute
        onSoundLevelChange: (level) {
          _stopCurrentRecording();
          _startRecording();
        },
      );
    } catch (e) {
      print('Error during recording: $e');
      _showErrorDialog1('Error while recording. Please restart the session.');
    }
  }

  void _showErrorDialog1(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _checkIfFormattingNeeded(String _speechText) {
    if (_speechText.trim().isEmpty) {
      print(
          "Speech text is empty. Skipping formatting and sending to TranscribeResult.");
      return false;
    } else {
      return true;
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _showAlertBox() {
    setState(() {
      _isKeepRecordingButtonActive = true;
      _isDiscardButtonActive = false;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        var mq = MediaQuery.of(context).size;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Adjust the radius here
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Discard Recording',
            style: GoogleFonts.spectral(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'You are exiting the recording. Recorded data will be lost.',
            style: GoogleFonts.karla(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isDiscardButtonActive = true;
                          _isKeepRecordingButtonActive = false;
                        });
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Discard',
                        style: GoogleFonts.karla(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _isDiscardButtonActive
                            ? Colors.white
                            : AppColors.ButtonColor2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppColors.ButtonColor2),
                        ),
                        backgroundColor: _isDiscardButtonActive
                            ? AppColors.ButtonColor2
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  child: Text(
                    'Keep Recording',
                    style: GoogleFonts.karla(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      // Add _restartRecordingSession() this function for start recording for starting for solving bug related to arrow back button not working properly
                      _restartRecordingSession();
                    });
                    // context.read<NavigationState>().updateLastScreen('record');
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _isKeepRecordingButtonActive
                        ? Colors.white
                        : AppColors.ButtonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.ButtonColor2),
                    ),
                    backgroundColor: _isKeepRecordingButtonActive
                        ? AppColors.ButtonColor2
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
              ),
              onPressed: () {
                _showAlertBox();
              },
            ),
            Text(
              "Record Transcript",
              style:
                  GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isProcessing) // Show LinearProgressIndicator when processing
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
                    child: LinearProgressIndicator(),
                  ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(mq.width * 0.025),
                    child: Container(
                      width: double.infinity,
                      height: mq.height * 0.2,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(220, 236, 235, 1.0),
                        // color: Colors.red,
                        borderRadius: BorderRadius.all(
                          Radius.circular(mq.width * 0.03),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isRecording ? _formatTime(_seconds) : "00:00",
                            style: GoogleFonts.karla(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: mq.height * 0.015),
                          Image.asset(
                            'assets1/audioWave.gif',
                            fit: BoxFit.cover,
                            height: mq.height * 0.12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: mq.height * 0.25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.ButtonColor2, // Red background color
                        shape: BoxShape.circle, // Circular shape
                      ),
                      padding: EdgeInsets.all(mq.width *
                          0.02), // Padding for the icon inside the circle
                      child: IconButton(
                        icon: Icon(
                          Icons.restart_alt, // Restart icon
                          color:
                              Colors.white, // Icon color (white for visibility)
                        ),
                        iconSize: mq.width * 0.08, // Responsive icon size
                        onPressed: () {
                          if (_isRecording) {
                            _showRestartAlert();
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 30,
                    ),

                    // Stop IconButton in a Circular Red Container
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.ButtonColor2, // Red background color
                        shape: BoxShape.circle, // Circular shape
                      ),
                      padding: EdgeInsets.all(mq.width *
                          0.02), // Padding for the icon inside the circle
                      child: IconButton(
                        icon: Icon(
                          Icons.stop, // Stop icon
                          color:
                              Colors.white, // Icon color (white for visibility)
                        ),
                        iconSize: mq.width * 0.08, // Responsive icon size
                        onPressed: _stopRecording,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
            if (_isLoading)

              // Show loading indicator if _isLoading is true
              if (_isLoading)
                Center(
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.white,
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: mq.width * 0.04,
                              vertical: mq.height * 0.1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                  height: 120,
                                  width: 120,
                                  child: Image.asset(
                                      "assets1/Sorting-Center.png")),
                              SizedBox(height: mq.height * 0.03),
                              Container(
                                height: 16,
                                width: 180,
                                child: LinearProgressIndicator(
                                  color: Color.fromRGBO(81, 160, 155, 1.0),
                                  backgroundColor: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              SizedBox(height: mq.height * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: mq.width * 0.05),
                                child: Text(
                                  'Please wait a moment while we prepare the polished transcript',
                                  style: GoogleFonts.karla(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
