//
//
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:manual_speech_to_text/manual_speech_to_text.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../core/viewmodels/get_api.dart';
// import '../auth/login_view.dart';
// import 'package:http/http.dart' as http;
// import '../nointernet.dart';
// import '../transcribe/transcribe_view.dart';
//
// class RecordView extends StatefulWidget {
//   final Function(String) onRecordingComplete;
//   final String tokenid;
//
//   RecordView({
//     required this.onRecordingComplete,
//     required this.tokenid,
//   });
//
//   @override
//   _RecordViewState createState() => _RecordViewState();
// }
//
// class _RecordViewState extends State<RecordView> with WidgetsBindingObserver {
//   late ManualSttController _sttController;
//   String _finalRecognizedText = "";
//   int _remainingTime = 180; // 3 minutes in seconds
//   Timer? _timer;
//   bool _isLoading = false;
//   bool _isListening = false;
//   final Connectivity _connectivity = Connectivity();
//   late final Stream<ConnectivityResult> _connectivityStream;
//   String _cumulativeText = "";
//   bool isPaused = false;
//   Timer? _silenceTimer;
//   List<String> recordedTexts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _sttController = ManualSttController(context);
//     _initializeSpeech();
//     _checkPermissionAndStartListening();
//     _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
//     _monitorInternet();
//
//   }
//
//   void _initializeSpeech() {
//     _sttController.listen(
//       onListeningStateChanged: (state) {
//         if (mounted) {
//           setState(() {
//             _isListening = (state == ManualSttState.listening);
//           });
//         }
//       },
//       onListeningTextChanged: (recognizedText) {
//         print("[Partial Recognized]: $recognizedText");
//         if (mounted) {
//           setState(() {
//             _finalRecognizedText = recognizedText;
//           });
//         }
//       },
//       onSoundLevelChanged: (level) {
//         if (level < 0.2) {
//           // If sound level is low, start silence timer
//           _silenceTimer?.cancel();
//           _silenceTimer = Timer(Duration(seconds: 4), () {
//             if (mounted && level < 0.2) {
//               setState(() {
//                 isPaused = true; // Show pause button
//               });
//             }
//           });
//         } else {
//           _silenceTimer?.cancel();
//           if (mounted) {
//             setState(() {
//               isPaused = false; // Show stop button if sound resumes
//             });
//           }
//         }
//       },
//     );
//
//     _sttController.pauseIfMuteFor = Duration(seconds: 60);
//     _sttController.enableHapticFeedback = true;
//     _sttController.localId = 'en-US';
//   }
//   Widget _buildRecordingButton() {
//     return GestureDetector(
//       onTap: () {
//         if (isPaused) {
//           // Resume recording
//           setState(() {
//             isPaused = false;
//           });
//           _sttController.startStt();
//         } else {
//           // Stop recording
//           _stopListening();
//         }
//       },
//       child: Container(
//         width: 60,
//         height: 60,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.red,
//         ),
//         child: Icon(
//           isPaused ? Icons.pause : Icons.stop, // Toggle button
//           color: Colors.white,
//           size: 30,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _checkPermissionAndStartListening() async {
//     try {
//       final status = await Permission.microphone.request();
//       if (status.isGranted) {
//         print('Microphone permission granted. Initializing STT...');
//         _startListening();
//         _startCountdown();
//       } else if (status.isDenied) {
//         print('Microphone permission denied.');
//         _stopCountdown();
//       } else if (status.isPermanentlyDenied) {
//         print(
//             'Microphone permission permanently denied. Please enable it in settings.');
//         openAppSettings();
//         _stopCountdown();
//       }
//     } catch (e) {
//       print('Error during permission check: $e');
//       _stopCountdown();
//     }
//   }
//
//   void _startListening() {
//     _sttController.pauseIfMuteFor = Duration(seconds: 60);
//     _sttController.startStt();
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (!_isListening && mounted) {
//         _sttController.resumeStt();
//       }
//     });
//   }
//
//   void _stopListening() {
//     _sttController.stopStt();
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (mounted) {
//         setState(() {
//           _cumulativeText += " " + _finalRecognizedText.trim();
//         });
//         print("Final recognized text: $_cumulativeText");
//         _sendFormattedTextToTranscribePage(_cumulativeText.trim());
//       }
//     });
//   }
//
//   void _pauseTimer() {
//     _timer?.cancel();
//   }
//
//   void _resumeTimer() {
//     if (_remainingTime > 0) {
//       _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//         if (!mounted) return;
//         setState(() {
//           if (_remainingTime > 0) {
//             _remainingTime--;
//           } else {
//             _stopListening();
//           }
//         });
//       });
//     }
//   }
//
//   Future<void> _onBackPressed() async {
//     print("Back arrow pressed");
//     _pauseTimer();
//     _sttController.stopStt();
//     bool? result = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           backgroundColor: Colors.white,
//           title: Text(
//             'Discard Recording',
//             style: GoogleFonts.spectral(
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           content: Text(
//             'You are exiting the recording. Recorded data will be lost.',
//             style: GoogleFonts.karla(
//               fontSize: 16,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all(Colors.white),
//                 side: WidgetStateProperty.all(
//                     BorderSide(color: AppColors.ButtonColor2)),
//                 padding: WidgetStateProperty.all(
//                     EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(false); // Discard
//               },
//               child: Text(
//                 'Discard',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   color: AppColors.ButtonColor2,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ),
//             TextButton(
//               style: ButtonStyle(
//                 backgroundColor:
//                     WidgetStateProperty.all(AppColors.ButtonColor2),
//                 padding: WidgetStateProperty.all(
//                     EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//                 // Keep Recording
//               },
//               child: Text(
//                 'Keep Recording',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//     if (result == true) {
//       setState(() {
//         _cumulativeText += " " + _finalRecognizedText.trim(); // Save previous session's text
//         _finalRecognizedText = ""; // Clear for the new session
//       });
//       _resumeTimer(); // Resume the timer
//       _sttController.startStt(); // Resume recording
//     } else {
//       Navigator.of(context).pop();
//     }
//   }
//
//   void _onRestartPressed() async {
//     _pauseTimer(); // Pause the timer
//     print("Timer paused");
//     _sttController.stopStt(); // Stop the recording
//     print("Recording paused");
//     bool? result = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20), // Adjust the radius here
//           ),
//           backgroundColor: Colors.white,
//           title: Text('Reset Recording'),
//           content: Text(
//               'Curent recording will be erased an a new one will be started '),
//           actions: <Widget>[
//             TextButton(
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all(Colors.white),
//                 side: WidgetStateProperty.all(
//                     BorderSide(color: AppColors.ButtonColor2)),
//                 padding: WidgetStateProperty.all(
//                     EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(false); // Discard
//               },
//               child: Text(
//                 'Discard',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   color: AppColors.ButtonColor2,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ),
//             TextButton(
//               style: ButtonStyle(
//                 backgroundColor:
//                     WidgetStateProperty.all(AppColors.ButtonColor2),
//                 side: WidgetStateProperty.all(
//                     BorderSide(color: AppColors.ButtonColor2)),
//                 padding: WidgetStateProperty.all(
//                     EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//               child: Text(
//                 'Reset',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//     if (result == true) {
//       setState(() {
//         _finalRecognizedText = ""; // Clear the current recognized text
//         _cumulativeText =
//             ""; // Clear cumulative text as well (no old text saved)
//         _remainingTime = 180;
//       });
//       _sttController.startStt(); // Start a new recording with manual_stt
//       _startCountdown();
//     } else {
//       setState(() {
//         _cumulativeText += " " + _finalRecognizedText.trim(); // Save old text
//         _finalRecognizedText = "";
//       });
//       _resumeTimer();
//       _sttController.startStt();
//     }
//   }
//
//   Future<void> _sendFormattedTextToTranscribePage(
//       String transcriptionToSend) async {
//     try {
//       bool isEmptyInput = transcriptionToSend.isEmpty;
//       Map<String, String>? formattedData =
//           await _formatText(transcriptionToSend);
//       if (formattedData != null && mounted) {
//         String formattedText = formattedData["transcript"] ?? transcriptionToSend;
//         String titleText = formattedData["title"] ?? 'Untitled';
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TranscribeResult(
//               transcribedText: formattedText,
//               unformattedText: transcriptionToSend,
//               isEmptyInput: isEmptyInput,
//               onDelete: () {
//                 widget.onRecordingComplete('');
//               },
//               tokenid: widget.tokenid,
//               title_text: titleText,
//             ),
//           ),
//         );
//       } else {
//         print('No formatted text available.');
//       }
//     } catch (e) {
//       print('Error sending formatted text: $e');
//     }
//   }
//
//   Future<Map<String, String>?> _formatText(String speechText) async {
//     if (!mounted) return null;
//     setState(() {
//       _isLoading = true;
//     });
//     const String apiUrl =
//         "https://dev-oscar.merakilearn.org/api/v1/optimize/optimize-text";
//     try {
//       final Map<String, String> body = {
//         "user_input": speechText,
//         "device_tag": '3', // Static device tag, adjust if needed
//       };
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {
//           'Authorization': 'Bearer ${widget.tokenid}',
//           'Content-Type': 'application/json; charset=UTF-8'
//         },
//         body: jsonEncode(body),
//       );
//       if (response.statusCode == 201) {
//         print('Request successful');
//         final responseData = jsonDecode(response.body);
//         final formattedText = responseData["data"]["transcript"] ?? speechText;
//         final formattedTitle = responseData["data"]["title"] ?? 'Untitled';
//         final formattedDate = responseData["data"]['createdAt'] ?? '';
//         return {
//           "title": formattedTitle,
//           "transcript": formattedText,
//           'date': formattedDate
//         };
//       } else if (response.statusCode == 401) {
//         print('Unauthorized');
//       } else if (response.statusCode == 429) {
//         print('Too many requests or daily quota exceeded');
//       } else if (response.statusCode == 500) {
//         print('Internal Server Error.');
//       } else {
//         print("Error: ${response.statusCode} - ${response.body}");
//         jsonDecode(response.body);
//       }
//     } catch (e) {
//       print("Error making POST request: $e");
//     }
//     finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//     return null;
//   }
//
//   void _startCountdown() {
//     _timer?.cancel();
//     _remainingTime = 180;
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       if (!mounted) return;
//       setState(() {
//         if (_remainingTime > 0) {
//           _remainingTime--;
//         } else {
//           _stopListening();
//         }
//       });
//     });
//   }
//
//   void _stopCountdown() {
//     _timer?.cancel();
//     _remainingTime = 180;
//     if (!mounted) return;
//     setState(() {});
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       print("App moved to background. Stopping recording.");
//       _sttController.stopStt();
//       _sttController.dispose();
//       _timer?.cancel();
//     } else if (state == AppLifecycleState.resumed) {
//       print("App returned to foreground.");
//     }
//   }
//
//   void _monitorInternet() {
//     _connectivityStream.listen((ConnectivityResult result) {
//       if (result == ConnectivityResult.none) {
//         _sttController.stopStt();
//         _timer?.cancel();
//         Navigator.of(context).push(MaterialPageRoute(
//           builder: (context) => NoInternetScreen(),
//         ));
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _sttController.stopStt();
//     _sttController.dispose();
//     _timer?.cancel();
//     _pauseTimer();
//     super.dispose();
//   }
//
//   bool _isProcessing = false;
//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: Colors.transparent,
//         title: Row(
//           children: [
//             IconButton(
//               icon: Icon(
//                 Icons.arrow_back_ios,
//                 size: 20,
//               ),
//               onPressed: () {
//                 _onBackPressed();
//               },
//             ),
//             Text(
//               "Record Transcript",
//               style:
//                   GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w700),
//             ),
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child:
//         Stack(
//           children: [
//             Column(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 if (_isProcessing) // Show LinearProgressIndicator when processing
//                   Padding(
//                     padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
//                     child: LinearProgressIndicator(),
//                   ),
//                 Center(
//                   child: Padding(
//                     padding: EdgeInsets.all(mq.width * 0.025),
//                     child: Container(
//                       width: double.infinity,
//                       height: mq.height * 0.2,
//                       decoration: BoxDecoration(
//                         color: Color.fromRGBO(220, 236, 235, 1.0),
//                         borderRadius: BorderRadius.all(
//                           Radius.circular(mq.width * 0.03),
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             _remainingTime > 0
//                                 ? '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
//                                 : 'Time is up!',
//                             style: GoogleFonts.karla(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.black,
//                             ),
//                           ),
//                           SizedBox(height: mq.height * 0.015),
//                           Image.asset(
//                             'assets1/audioWave.gif',
//                             fit: BoxFit.cover,
//                             height: mq.height * 0.12,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: mq.height * 0.25),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         color: AppColors.ButtonColor2,
//                         shape: BoxShape.circle, // Circular shape
//                       ),
//                       padding: EdgeInsets.all(mq.width *
//                           0.02), // Padding for the icon inside the circle
//                       child: IconButton(
//                         icon: Icon(
//                           Icons.restart_alt,
//                           color: Colors.white,
//                         ),
//                         iconSize: mq.width * 0.08,
//                         onPressed: () {
//                           _onRestartPressed();
//                         },
//                       ),
//                     ),
//                     SizedBox(
//                       width: 30,
//                     ),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: AppColors.ButtonColor2,
//                         shape: BoxShape.circle,
//                       ),
//                       padding: EdgeInsets.all(mq.width * 0.02),
//                       child:
//                       // _buildRecordingButton(),
//
//                       IconButton(
//                         icon: Icon(
//                           // isPaused ? Icons.stop : Icons.play_arrow,
//                           Icons.stop,
//                           color: Colors.white,
//                         ),
//                         iconSize: mq.width * 0.08,
//                         onPressed: _stopListening,
//                       ),
//                     ),
//                     ],
//                 ),
//                 SizedBox(
//                   height: 20,
//                 ),
//               ],
//             ),
//             if (_isLoading)
//               Center(
//                 child: Stack(
//                   children: [
//                     Container(
//                       color: Colors.white,
//                     ),
//                     Center(
//                       child: Padding(
//                         padding: EdgeInsets.symmetric(
//                             horizontal: mq.width * 0.04,
//                             vertical: mq.height * 0.1),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Container(
//                                 height: 120,
//                                 width: 120,
//                                 child:
//                                     Image.asset("assets1/Sorting-Center.png")),
//                             SizedBox(height: mq.height * 0.03),
//                             Container(
//                               height: 16,
//                               width: 180,
//                               child: LinearProgressIndicator(
//                                 color: Color.fromRGBO(81, 160, 155, 1.0),
//                                 backgroundColor: Colors.grey[200],
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                             SizedBox(height: mq.height * 0.03),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: mq.width * 0.05),
//                               child: Text(
//                                 'Please wait a moment while we prepare the polished transcript',
//                                 style: GoogleFonts.karla(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
