
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:testing_oscar/ui/views/CombinedScreenProvider.dart';
import '../../../core/constants/app_colors.dart';
import 'package:http/http.dart' as http;
import '../CombinedScreenProvider.dart';
import '../nointernet.dart';
import '../transcribe/transcribe_view.dart';

class SpeechService {
  static SpeechService? _instance;
  final ManualSttController _speech;

  // Private constructor
  SpeechService._internal(BuildContext context) : _speech = ManualSttController(context);

  // Factory constructor to return the singleton instance
  factory SpeechService(BuildContext context) {
    _instance ??= SpeechService._internal(context);
    return _instance!;
  }

  // Getter for the speech instance
  ManualSttController get speechInstance => _speech;

  // Dispose method to clean up resource.
Future<void> dispose() async {
  await _speech.pauseStt;
  print("SpeechService disposed.");
}

}

class RecordView extends StatefulWidget {
  final Function(String) onRecordingComplete;
  final String tokenid;

  const RecordView({Key? key,required this.onRecordingComplete, required this.tokenid,}) : super(key: key);

  @override
  _RecordViewState createState() => _RecordViewState();
}


class _RecordViewState extends State<RecordView> with WidgetsBindingObserver {
  int _remainingTime = 180; // 3 minutes in seconds
  Timer? _timer;
  final Connectivity _connectivity = Connectivity();
  late final Stream<ConnectivityResult> _connectivityStream;
  bool _isProcessing = false;
  bool _isLoading = false;
  late ManualSttController _speech;
  bool _isListening = false;
  String _finalRecognizedText = "";
  String _cumulativeText = "";





  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndStartListening();
    _speech = SpeechService(context).speechInstance;
    _initSpeech();
    _initializeSpeech();
    _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
    _monitorInternet();
  }

  void _initSpeech() async {
    try{
      await _speech.startStt;
      print("Speech-to-text started successfully.");
      setState(() {});
    } catch (e){
      print("Failed to start speech recognition: $e");
    }
  }

  void _initializeSpeech() {
    _speech.listen(
      onListeningStateChanged: (state) {
        if (mounted) {
          setState(() {
            _isListening = (state == ManualSttState.listening);
          });
        }
      },
      onListeningTextChanged: (recognizedText) {
        print("[Partial Recognized]: $recognizedText");
        if (mounted) {
          setState(() {
            _finalRecognizedText = recognizedText;
          });
        }
      },
      onSoundLevelChanged: (level) {
        log("Sound level: $level");
        if (!_isListening && level > 0.5) {
          log("Sound detected after pause. Resuming recording...");
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              _speech.startStt();
            }
          });
        }
      },
    );

    _speech.pauseIfMuteFor = Duration(seconds: 60);
    _speech.enableHapticFeedback = true;
    _speech.localId = 'en-US';
  }

  Future<void> _sendFormattedTextToTranscribePage(String transcriptionToSend) async {
    try {

      bool isEmptyInput = transcriptionToSend.isEmpty;

      Map<String, String>? formattedData = await _formatText(transcriptionToSend);

      if (formattedData != null && mounted) {


        String formattedText = formattedData["transcript"] ?? transcriptionToSend;
        String titleText = formattedData["title"] ?? 'Untitled';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TranscribeResult(
              transcribedText: formattedText,
              unformattedText: transcriptionToSend,
              isEmptyInput: isEmptyInput,
              onDelete: () {
                widget.onRecordingComplete('');
              },
              tokenid: widget.tokenid,
              title_text: titleText,
            ),
          ),
        );
      } else {
        print('No formatted text available.');
      }
    } catch (e) {
      print('Error sending formatted text: $e');
    }
  }

  Future<void> _checkPermissionAndStartListening() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        print('Microphone permission granted. Initializing STT...');
        _startListening();
        _startCountdown();
      } else if (status.isDenied) {
        print('Microphone permission denied.');
        _stopCountdown();
      } else if (status.isPermanentlyDenied) {
        print('Microphone permission permanently denied. Please enable it in settings.');
        openAppSettings();
        _stopCountdown();
      }
    } catch (e) {
      print('Error during permission check: $e');
      _stopCountdown();
    }
  }
  void _startListening() {
    _speech.pauseIfMuteFor = Duration(seconds :60);
    _speech.startStt();

    Future.delayed(Duration(milliseconds: 2), (){
      if (!_isListening && mounted) {
        _speech.resumeStt();
      }
    });
  }

  void _stopListening() async {
    await _speech.stopStt;

    try {
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _cumulativeText += " " + _finalRecognizedText.trim();
        });

        print("Final recognized text: $_cumulativeText");
        await _sendFormattedTextToTranscribePage(_cumulativeText.trim());
      }
    } catch (e) {
      print("Error during stop listening: $e");
    }
  }


  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // widget.controller.stopStt();

        // Navigate to the NoInternetScreen
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => NoInternetScreen(),
        ));
      }
    });
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // widget.controller.stopStt(); // Stop recording when app goes to background
    }
  }

  Future<Map<String, String>?> _formatText(String speechText) async {
    if (!mounted) return null;
    setState(() {
      _isLoading = true;
    });
    const String apiurl = "https://dev-oscar.merakilearn.org/api/v1/optimize/optimize-text";

    try {
      final Map<String, String> body = {
        "user_input": speechText,
        "device_tag": '3',
      };
      final response = await http.post(
          Uri.parse(apiurl),
          headers: {
            'Authorization': 'Bearer ${widget.tokenid}',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(body)
      );
      if (response.statusCode == 201) {
        print("Request successful");
        final responseData = jsonDecode(response.body);
        final formattedText = responseData["data"]["transcript"] ?? speechText;
        final formattedTitle = responseData["data"]["title"] ?? 'Untitled';
        final formattedDate = responseData["data"]['createdAt'] ?? '';
        return {
          "title": formattedTitle,
          "transcript": formattedText,
          'date': formattedDate,
        };
      }
      else if (response.statusCode == 400) {
        return  {
          "title": '',
          "transcript": '',
          'date': '',
        };
      }
      else if (response.statusCode == 401) {
        print('Unauthorized');
      } else if (response.statusCode == 429) {
        print('Too many requests or daily quota exceeded');
      } else if (response.statusCode == 500) {
        print('Internal Server Error.');
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        jsonDecode(response.body);
      }}

    catch (e) {
      print("Error making POST request: $e");
    }

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resumeTimer() {
    if (_remainingTime > 0) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            // widget.controller.stopStt();
          }
        });
      });
    }
  }
  void _startCountdown() {
    _timer?.cancel();
    _remainingTime = 180;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          // widget.controller.stopStt();
        }
      });
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    _remainingTime = 180;
    if (!mounted) return;
    setState(() {});
  }


  void _pauseTimer() {
    _timer?.cancel();}

  Future<void> _onBackPressed() async {
    // Print("Back arrow pressed");
    _pauseTimer();
    _speech.pauseStt();
    // widget.controller.pauseStt();
    bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text('Discard Recording',
                style: GoogleFonts.spectral(
                    fontSize: 20,
                    fontWeight: FontWeight.w700
                ),),
              content: Text(
                'Any recorded speech will be lost and will need to be recorded again',
                style: GoogleFonts.karla(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: <Widget> [
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    side: WidgetStateProperty.all(
                        BorderSide(color: AppColors.ButtonColor2)),
                    padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Close the dialog
                  },
                  child: Text(
                    'Discard',
                    style: GoogleFonts.karla(
                      fontSize: 16,
                      color: AppColors.ButtonColor2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.all(AppColors.ButtonColor2),
                    padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    // Keep Recording
                  },
                  child: Text(
                    'Keep Recording',
                    style: GoogleFonts.karla(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),

              ]
          );
        }
    );
    if (result == true) {
      // widget.controller.resumeStt();
      setState(() {
        _cumulativeText +=
            " " + _finalRecognizedText.trim(); 
        _finalRecognizedText = ""; 
      });
      _resumeTimer();
      _speech.startStt();
      // _startCountdown();
    } else {
      Navigator.of(context).pop();
      // Provider.of<AppState>(context, listen: false).navigateToHomePage();
    }
  }

  void _onRestartPressed() async {
    _pauseTimer(); // Pause the timer
    print("Timer paused");
    _speech.pauseStt();
    // widget.controller.pauseStt(); // Stop the recording
    print("Recording paused");
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Adjust the radius here
          ),
          backgroundColor: Colors.white,
          title: Text('Reset Recording',style: GoogleFonts.spectral(
                    fontSize: 20,
                    fontWeight: FontWeight.w700
                ),),
          content: Text(
              'Curent recording will be erased and a new one will be started ',
              style: GoogleFonts.karla(
                    fontSize: 16,
                    fontWeight: FontWeight.w400
                ),
              
              ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(
                    BorderSide(color: AppColors.ButtonColor2)),
                padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.karla(
                  fontSize: 16,
                  color: AppColors.ButtonColor2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor:
                WidgetStateProperty.all(AppColors.ButtonColor2),
                side: WidgetStateProperty.all(
                    BorderSide(color: AppColors.ButtonColor2)),
                padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Reset',
                style: GoogleFonts.karla(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (result == true){
      // widget.controller.startStt();
      setState(() {
        _finalRecognizedText = ""; 
        _cumulativeText =
        ""; 
        _remainingTime = 180; 
      });

      _speech.startStt();
      _startCountdown();
    } else {
      setState(() {
        _cumulativeText += " " + _finalRecognizedText.trim(); 
        _finalRecognizedText = "";
      });
      _resumeTimer();
      _speech.startStt();
      // widget.controller.resumeStt();
    }
    // if (result == true) {
    //   _resetRecording(); // Call method to restart recording
    // } else {
    //   _resumeRecording(); // Resume recording if discarded
    // }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SpeechService(context).dispose(); // Dispose the Singleton instance
    _speech.dispose();
    _timer?.cancel();
    _pauseTimer();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    // final appState = Provider.of<AppState>(context);

    return
      WillPopScope(
        onWillPop: () async {
          // Provider.of<AppState>(context, listen: false).navigateToHomePage();
          return true; // Prevent default back navigation
        },
        child: Scaffold(
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
                    _onBackPressed();
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
                    if (_isProcessing)
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
                            borderRadius: BorderRadius.all(
                              Radius.circular(mq.width * 0.03),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              Text(
                                _remainingTime > 0
                                    ? '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
                                    : 'Time is up!',
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

                    // Text("Final text: ${appState.finalRecognizedText}",style: TextStyle(fontSize: 12),),

                    SizedBox(height: mq.height * 0.25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.ButtonColor2,
                            shape: BoxShape.circle, // Circular shape
                          ),
                          padding: EdgeInsets.all(mq.width *
                              0.02), // Padding for the icon inside the circle
                          child: IconButton(
                            icon: Icon(
                              Icons.restart_alt,
                              color: Colors.white,
                            ),
                            iconSize: mq.width * 0.08,
                            onPressed: () {
                              _onRestartPressed();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 30,
                        ),

                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.ButtonColor2,
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(mq.width * 0.02),
                          child:
                          // _buildRecordingButton(),

                          IconButton(
                              icon: Icon(
                                // isPaused ? Icons.stop : Icons.play_arrow,
                                Icons.stop,
                                color: Colors.white,
                              ),
                              iconSize: mq.width * 0.08,
                              // onPressed: () async {
                              //   widget.controller.stopStt();
                              //
                              //   // Debug log to check the value of finalRecognizedText
                              //   print('Final Recognized Text: "${appState.finalRecognizedText}"');
                              //   print('Is Final Recognized Text Empty: ${appState.finalRecognizedText.trim().isEmpty}');
                              //
                              //   if (appState.finalRecognizedText.trim().isEmpty) {
                              //     // Debug log to confirm the condition is met
                              //     print('Navigating to RecordView');
                              //
                              //     // Navigate to RecordView
                              //     appState.navigateToRecordingPage();
                              //   } else {
                              //     await _sendFormattedTextToTranscribePage(appState.finalRecognizedText);
                              //     appState.clearFinalRecognizedText();
                              //   }
                              // }

                              onPressed:
                                _stopListening

                                // widget.controller.stopStt();
                                // print('Final Recognized Text: "${appState.finalRecognizedText}"');
                                // print('Is Final Recognized Text Empty: ${appState.finalRecognizedText.trim().isEmpty}');
                                // await _sendFormattedTextToTranscribePage(appState.finalRecognizedText);
                                // appState.clearFinalRecognizedText();


                          ),
                        )
                      ],
                    ),
                  ],
                ),

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
                                    child:
                                    Image.asset("assets1/Sorting-Center.png")),
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
        ),
      );
  }
}


//////////////////////////////////////////////////////////////////////

// class _RecordViewState extends State<RecordView> with WidgetsBindingObserver {
//   int _remainingTime = 180; // 3 minutes in seconds
//   Timer? _timer;
//   final Connectivity _connectivity = Connectivity();
//   late final Stream<ConnectivityResult> _connectivityStream;
//   bool _isProcessing = false;
//   bool _isLoading = false;
//   late ManualSttController _speech;
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     widget.controller.startStt();
//     _startCountdown();
//     WidgetsBinding.instance.addObserver(this);
//     _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
//     _monitorInternet();
//   }
//
//   // Future<void> _checkMicrophonePermission() async {
//   //   var status = await Permission.microphone.status;
//   //
//   //   if (!status.isGranted) {
//   //     status = await Permission.microphone.request();
//   //   }
//   //
//   //   // Start recording only if permission is granted
//   //   if (await Permission.microphone.isGranted && mounted) {
//   //     widget.controller.startStt();
//   //     print("Recording started after permission granted.");
//   //   }
//   // }
//
//   // void _startRecording() async {
//   //   if (widget.controller.isAvailable) {
//   //     setState(() {
//   //       isRecording = true;
//   //     });
//   //     widget.controller.startStt(); // Start recording
//   //   } else {
//   //     print("Speech-to-text controller is not available.");
//   //   }
//   // }
//   void _monitorInternet() {
//     _connectivityStream.listen((ConnectivityResult result) {
//       if (result == ConnectivityResult.none) {
//         widget.controller.stopStt();
//
//         // Navigate to the NoInternetScreen
//         Navigator.of(context).pushReplacement(MaterialPageRoute(
//           builder: (context) => NoInternetScreen(),
//         ));
//       }
//     });
//   }
//
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
//       widget.controller.stopStt(); // Stop recording when app goes to background
//     }
//   }
//
//   Future<void> _sendFormattedTextToTranscribePage(String transcriptionToSend)  async {
//     try{
//       setState(() {
//         _isLoading = true; // Show loading indicator
//       });
//       Map<String,String>? formattedData = await _formatText(transcriptionToSend);
//       if (formattedData != null && mounted) {
//         String titleText = formattedData["title"] ?? 'Untitled';
//         String formattedText = formattedData["transcript"] ?? transcriptionToSend;
//         // final appState = Provider.of<AppState> (context, listen: false);
//         // appState.updateFormattedText(formattedText, transcriptionToSend, titleText);
//         // appState.navigateToTranscriptionPage();
//       } else {
//         print('No formatted text available.');
//       }
//     } catch (e){
//       print('Error sending formatted text: $e');
//     }
//   }
//
//   Future<Map<String, String>?> _formatText(String speechText) async {
//     if (!mounted) return null;
//     setState(() {
//       _isLoading = true;
//     });
//     const String apiurl = "https://dev-oscar.merakilearn.org/api/v1/optimize/optimize-text";
//
//     try {
//       final Map<String, String> body = {
//         "user_input": speechText,
//         "device_tag": '3',
//       };
//       final response = await http.post(
//           Uri.parse(apiurl),
//           headers: {
//             'Authorization': 'Bearer ${widget.tokenid}',
//             'Content-Type': 'application/json; charset=UTF-8',
//           },
//           body: jsonEncode(body)
//       );
//       if (response.statusCode == 201) {
//         print("Request successful");
//         final responseData = jsonDecode(response.body);
//         final formattedText = responseData["data"]["transcript"] ?? speechText;
//         final formattedTitle = responseData["data"]["title"] ?? 'Untitled';
//         final formattedDate = responseData["data"]['createdAt'] ?? '';
//         return {
//           "title": formattedTitle,
//           "transcript": formattedText,
//           'date': formattedDate,
//         };
//       }
//       else if (response.statusCode == 400) {
//         return  {
//           "title": '',
//           "transcript": '',
//           'date': '',
//         };
//       }
//       else if (response.statusCode == 401) {
//         print('Unauthorized');
//       } else if (response.statusCode == 429) {
//         print('Too many requests or daily quota exceeded');
//       } else if (response.statusCode == 500) {
//         print('Internal Server Error.');
//       } else {
//         print("Error: ${response.statusCode} - ${response.body}");
//         jsonDecode(response.body);
//       }}
//
//     catch (e) {
//       print("Error making POST request: $e");
//     }
//
//     finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
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
//             widget.controller.stopStt();
//           }
//         });
//       });
//     }
//   }
//   void _startCountdown() {
//     _timer?.cancel();
//     _remainingTime = 180;
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       if (!mounted) return;
//       setState(() {
//         if (_remainingTime > 0) {
//           _remainingTime--;
//         } else {
//           widget.controller.stopStt();
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
//
//   void _pauseTimer() {
//     _timer?.cancel();}
//
//   Future<void> _onBackPressed() async {
//     // Print("Back arrow pressed");
//     _pauseTimer();
//     widget.controller.pauseStt();
//     bool? result = await showDialog<bool>(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               backgroundColor: Colors.white,
//               title: Text('Discard Recording',
//                 style: GoogleFonts.spectral(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700
//                 ),),
//               content: Text(
//                 'You are exiting the recording. Recorded data will be lost.',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               actions: <Widget> [
//                 TextButton(
//                   style: ButtonStyle(
//                     backgroundColor: WidgetStateProperty.all(Colors.white),
//                     side: WidgetStateProperty.all(
//                         BorderSide(color: AppColors.ButtonColor2)),
//                     padding: WidgetStateProperty.all(
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//                   ),
//                   onPressed: () {
//                     Navigator.of(context).pop(); // Close the dialog
//                   },
//                   child: Text(
//                     'Discard',
//                     style: GoogleFonts.karla(
//                       fontSize: 16,
//                       color: AppColors.ButtonColor2,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ),
//                 TextButton(
//                   style: ButtonStyle(
//                     backgroundColor:
//                     WidgetStateProperty.all(AppColors.ButtonColor2),
//                     padding: WidgetStateProperty.all(
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//                   ),
//                   onPressed: () {
//                     Navigator.of(context).pop(true);
//                     // Keep Recording
//                   },
//                   child: Text(
//                     'Keep Recording',
//                     style: GoogleFonts.karla(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w400,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//
//               ]
//           );
//         }
//     );
//     if (result == true) {
//       widget.controller.resumeStt();
//       _startCountdown();
//     } else {
//       // Provider.of<AppState>(context, listen: false).navigateToHomePage();
//     }
//   }
//
//   void _onRestartPressed() async {
//     _pauseTimer(); // Pause the timer
//     print("Timer paused");
//     widget.controller.pauseStt(); // Stop the recording
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
//                 Navigator.of(context).pop(); // Close the dialog
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
//                 WidgetStateProperty.all(AppColors.ButtonColor2),
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
//     if (result == true){
//       widget.controller.startStt();
//       _startCountdown();
//     } else {
//       widget.controller.resumeStt();
//     }
//     // if (result == true) {
//     //   _resetRecording(); // Call method to restart recording
//     // } else {
//     //   _resumeRecording(); // Resume recording if discarded
//     // }
//   }
//
//
//   @override
//   void dispose() {
//     widget.controller.stopStt();
//     _timer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;
//     // final appState = Provider.of<AppState>(context);
//
//     return
//       WillPopScope(
//         onWillPop: () async {
//           // Provider.of<AppState>(context, listen: false).navigateToHomePage();
//           return false; // Prevent default back navigation
//         },
//         child: Scaffold(
//           backgroundColor: Colors.white,
//           appBar: AppBar(
//             automaticallyImplyLeading: false,
//             backgroundColor: Colors.transparent,
//             title: Row(
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back_ios,
//                     size: 20,
//                   ),
//                   onPressed: () {
//                     _onBackPressed();
//                   },
//                 ),
//                 Text(
//                   "Record Transcript",
//                   style:
//                   GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w700),
//                 ),
//               ],
//             ),
//           ),
//           body: Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Stack(
//               children: [
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     if (_isProcessing)
//                       Padding(
//                         padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
//                         child: LinearProgressIndicator(),
//                       ),
//                     Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(mq.width * 0.025),
//                         child: Container(
//                           width: double.infinity,
//                           height: mq.height * 0.2,
//                           decoration: BoxDecoration(
//                             color: Color.fromRGBO(220, 236, 235, 1.0),
//                             borderRadius: BorderRadius.all(
//                               Radius.circular(mq.width * 0.03),
//                             ),
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//
//                               Text(
//                                 _remainingTime > 0
//                                     ? '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
//                                     : 'Time is up!',
//                                 style: GoogleFonts.karla(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               SizedBox(height: mq.height * 0.015),
//
//                               Image.asset(
//                                 'assets1/audioWave.gif',
//                                 fit: BoxFit.cover,
//                                 height: mq.height * 0.12,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     // Text("Final text: ${appState.finalRecognizedText}",style: TextStyle(fontSize: 12),),
//
//                     SizedBox(height: mq.height * 0.25),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.ButtonColor2,
//                             shape: BoxShape.circle, // Circular shape
//                           ),
//                           padding: EdgeInsets.all(mq.width *
//                               0.02), // Padding for the icon inside the circle
//                           child: IconButton(
//                             icon: Icon(
//                               Icons.restart_alt,
//                               color: Colors.white,
//                             ),
//                             iconSize: mq.width * 0.08,
//                             onPressed: () {
//                               _onRestartPressed();
//                             },
//                           ),
//                         ),
//                         SizedBox(
//                           width: 30,
//                         ),
//
//                         Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.ButtonColor2,
//                             shape: BoxShape.circle,
//                           ),
//                           padding: EdgeInsets.all(mq.width * 0.02),
//                           child:
//                           // _buildRecordingButton(),
//
//                           IconButton(
//                               icon: Icon(
//                                 // isPaused ? Icons.stop : Icons.play_arrow,
//                                 Icons.stop,
//                                 color: Colors.white,
//                               ),
//                               iconSize: mq.width * 0.08,
//                               // onPressed: () async {
//                               //   widget.controller.stopStt();
//                               //
//                               //   // Debug log to check the value of finalRecognizedText
//                               //   print('Final Recognized Text: "${appState.finalRecognizedText}"');
//                               //   print('Is Final Recognized Text Empty: ${appState.finalRecognizedText.trim().isEmpty}');
//                               //
//                               //   if (appState.finalRecognizedText.trim().isEmpty) {
//                               //     // Debug log to confirm the condition is met
//                               //     print('Navigating to RecordView');
//                               //
//                               //     // Navigate to RecordView
//                               //     appState.navigateToRecordingPage();
//                               //   } else {
//                               //     await _sendFormattedTextToTranscribePage(appState.finalRecognizedText);
//                               //     appState.clearFinalRecognizedText();
//                               //   }
//                               // }
//
//                               onPressed: () async {
//                                 widget.controller.stopStt();
//                                 // print('Final Recognized Text: "${appState.finalRecognizedText}"');
//                                 // print('Is Final Recognized Text Empty: ${appState.finalRecognizedText.trim().isEmpty}');
//                                 // await _sendFormattedTextToTranscribePage(appState.finalRecognizedText);
//                                 // appState.clearFinalRecognizedText();
//                               }
//
//                           ),
//                         )
//                       ],
//                     ),
//                   ],
//                 ),
//
//                 if (_isLoading)
//                   Center(
//                     child: Stack(
//                       children: [
//                         Container(
//                           color: Colors.white,
//                         ),
//                         Center(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: mq.width * 0.04,
//                                 vertical: mq.height * 0.1),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Container(
//                                     height: 120,
//                                     width: 120,
//                                     child:
//                                     Image.asset("assets1/Sorting-Center.png")),
//                                 SizedBox(height: mq.height * 0.03),
//                                 Container(
//                                   height: 16,
//                                   width: 180,
//                                   child: LinearProgressIndicator(
//                                     color: Color.fromRGBO(81, 160, 155, 1.0),
//                                     backgroundColor: Colors.grey[200],
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                 ),
//                                 SizedBox(height: mq.height * 0.03),
//                                 Padding(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: mq.width * 0.05),
//                                   child: Text(
//                                     'Please wait a moment while we prepare the polished transcript',
//                                     style: GoogleFonts.karla(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w400,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//               ],
//             ),
//           ),
//         ),
//       );
//   }
// }










// import 'dart:convert';
// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:manual_speech_to_text/manual_speech_to_text.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// // import 'package:testing_oscar/ui/views/CombinedScreenProvider.dart';
// import '../../../core/constants/app_colors.dart';
// import 'package:http/http.dart' as http;
// import '../CombinedScreenProvider.dart';
// import '../nointernet.dart';
// import '../transcribe/transcribe_view.dart';
//
// class RecordView extends StatefulWidget {
//   final ManualSttController controller;
//   final String tokenid;
//
//   const RecordView({Key? key, required this.controller,required this.tokenid,}) : super(key: key);
//
//   @override
//   _RecordViewState createState() => _RecordViewState();
// }
//
// class _RecordViewState extends State<RecordView> with WidgetsBindingObserver {
//   int _remainingTime = 180; // 3 minutes in seconds
//   Timer? _timer;
//   final Connectivity _connectivity = Connectivity();
//   late final Stream<ConnectivityResult> _connectivityStream;
//   bool _isProcessing = false;
//   bool _isLoading = false;
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     // WidgetsBinding.instance.addPostFrameCallback((_) async {
//     //   await _checkMicrophonePermission();
//     // });
//     widget.controller.startStt();
//     _startCountdown();
//     WidgetsBinding.instance.addObserver(this);
//     // Provider.of<AppState>(context, listen: false).monitorInternet(context);
//     _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
//     _monitorInternet();
//     // WidgetsBinding.instance.addPostFrameCallback((_) {
//     //   final appState = Provider.of<AppState>(context, listen: false);
//     //   if (appState.currentState != ManualSttState.listening) {
//     //     widget.controller.startStt(); // Start recording
//     //   }
//     // });
//
//     // WidgetsBinding.instance.addPostFrameCallback((_) async {
//     //   final appState = Provider.of<AppState>(context, listen: false);
//     //   var status = await Permission.microphone.status;
//     //   if (status.isGranted && appState.currentState != ManualSttState.listening) {
//     //     widget.controller.startStt(); // Start recording
//     //   }
//     // });
//
//   }
//
//   // Future<void> _checkMicrophonePermission() async {
//   //   var status = await Permission.microphone.status;
//   //
//   //   if (!status.isGranted) {
//   //     status = await Permission.microphone.request();
//   //   }
//   //
//   //   // Start recording only if permission is granted
//   //   if (await Permission.microphone.isGranted && mounted) {
//   //     widget.controller.startStt();
//   //     print("Recording started after permission granted.");
//   //   }
//   // }
//
//   // void _startRecording() async {
//   //   if (widget.controller.isAvailable) {
//   //     setState(() {
//   //       isRecording = true;
//   //     });
//   //     widget.controller.startStt(); // Start recording
//   //   } else {
//   //     print("Speech-to-text controller is not available.");
//   //   }
//   // }
//   void _monitorInternet() {
//     _connectivityStream.listen((ConnectivityResult result) {
//       if (result == ConnectivityResult.none) {
//         widget.controller.stopStt();
//
//         // Navigate to the NoInternetScreen
//         Navigator.of(context).pushReplacement(MaterialPageRoute(
//           builder: (context) => NoInternetScreen(),
//         ));
//       }
//     });
//   }
//
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
//       widget.controller.stopStt(); // Stop recording when app goes to background
//     }
//   }
//
//   Future<void> _sendFormattedTextToTranscribePage(String transcriptionToSend)  async {
//     try{
//       setState(() {
//         _isLoading = true; // Show loading indicator
//       });
//       Map<String,String>? formattedData = await _formatText(transcriptionToSend);
//       if (formattedData != null && mounted) {
//         String titleText = formattedData["title"] ?? 'Untitled';
//         String formattedText = formattedData["transcript"] ?? transcriptionToSend;
//         final appState = Provider.of<AppState> (context, listen: false);
//         appState.updateFormattedText(formattedText, transcriptionToSend, titleText);
//         appState.navigateToTranscriptionPage();
//       } else {
//         print('No formatted text available.');
//       }
//     } catch (e){
//       print('Error sending formatted text: $e');
//     }
//   }
//
//   Future<Map<String, String>?> _formatText(String speechText) async {
//     if (!mounted) return null;
//     setState(() {
//       _isLoading = true;
//     });
//     const String apiurl = "https://dev-oscar.merakilearn.org/api/v1/optimize/optimize-text";
//
//     try {
//       final Map<String, String> body = {
//         "user_input": speechText,
//         "device_tag": '3',
//       };
//       final response = await http.post(
//           Uri.parse(apiurl),
//           headers: {
//             'Authorization': 'Bearer ${widget.tokenid}',
//             'Content-Type': 'application/json; charset=UTF-8',
//           },
//           body: jsonEncode(body)
//       );
//       if (response.statusCode == 201) {
//         print("Request successful");
//         final responseData = jsonDecode(response.body);
//         final formattedText = responseData["data"]["transcript"] ?? speechText;
//         final formattedTitle = responseData["data"]["title"] ?? 'Untitled';
//         final formattedDate = responseData["data"]['createdAt'] ?? '';
//         return {
//           "title": formattedTitle,
//           "transcript": formattedText,
//           'date': formattedDate,
//         };
//       }
//       else if (response.statusCode == 400) {
//         return  {
//           "title": '',
//           "transcript": '',
//           'date': '',
//         };
//       }
//       else if (response.statusCode == 401) {
//         print('Unauthorized');
//       } else if (response.statusCode == 429) {
//         print('Too many requests or daily quota exceeded');
//       } else if (response.statusCode == 500) {
//         print('Internal Server Error.');
//       } else {
//         print("Error: ${response.statusCode} - ${response.body}");
//         jsonDecode(response.body);
//       }}
//
//     catch (e) {
//       print("Error making POST request: $e");
//     }
//
//     finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
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
//             widget.controller.stopStt();
//           }
//         });
//       });
//     }
//   }
//   void _startCountdown() {
//     _timer?.cancel();
//     _remainingTime = 180;
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       if (!mounted) return;
//       setState(() {
//         if (_remainingTime > 0) {
//           _remainingTime--;
//         } else {
//           widget.controller.stopStt();
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
//
//   void _pauseTimer() {
//     _timer?.cancel();}
//
//   Future<void> _onBackPressed() async {
//     // Print("Back arrow pressed");
//     _pauseTimer();
//     widget.controller.pauseStt();
//     bool? result = await showDialog<bool>(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               backgroundColor: Colors.white,
//               title: Text('Discard Recording',
//                 style: GoogleFonts.spectral(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700
//                 ),),
//               content: Text(
//                 'You are exiting the recording. Recorded data will be lost.',
//                 style: GoogleFonts.karla(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               actions: <Widget> [
//                 TextButton(
//                   style: ButtonStyle(
//                     backgroundColor: WidgetStateProperty.all(Colors.white),
//                     side: WidgetStateProperty.all(
//                         BorderSide(color: AppColors.ButtonColor2)),
//                     padding: WidgetStateProperty.all(
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//                   ),
//                   onPressed: () {
//                     Navigator.of(context).pop(); // Close the dialog
//                   },
//                   child: Text(
//                     'Discard',
//                     style: GoogleFonts.karla(
//                       fontSize: 16,
//                       color: AppColors.ButtonColor2,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ),
//                 TextButton(
//                   style: ButtonStyle(
//                     backgroundColor:
//                     WidgetStateProperty.all(AppColors.ButtonColor2),
//                     padding: WidgetStateProperty.all(
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//                   ),
//                   onPressed: () {
//                     Navigator.of(context).pop(true);
//                     // Keep Recording
//                   },
//                   child: Text(
//                     'Keep Recording',
//                     style: GoogleFonts.karla(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w400,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//
//               ]
//           );
//         }
//     );
//     if (result == true) {
//       widget.controller.resumeStt();
//       _startCountdown();
//     } else {
//       Provider.of<AppState>(context, listen: false).navigateToHomePage();
//     }
//   }
//
//   void _onRestartPressed() async {
//     _pauseTimer(); // Pause the timer
//     print("Timer paused");
//     widget.controller.pauseStt(); // Stop the recording
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
//                 Navigator.of(context).pop(); // Close the dialog
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
//                 WidgetStateProperty.all(AppColors.ButtonColor2),
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
//     if (result == true){
//       widget.controller.startStt();
//       _startCountdown();
//     } else {
//       widget.controller.resumeStt();
//     }
//     // if (result == true) {
//     //   _resetRecording(); // Call method to restart recording
//     // } else {
//     //   _resumeRecording(); // Resume recording if discarded
//     // }
//   }
//
//
//   @override
//   void dispose() {
//     widget.controller.stopStt();
//     _timer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;
//     final appState = Provider.of<AppState>(context);
//
//     return
//       WillPopScope(
//         onWillPop: () async {
//           Provider.of<AppState>(context, listen: false).navigateToHomePage();
//           return false; // Prevent default back navigation
//         },
//         child: Scaffold(
//           backgroundColor: Colors.white,
//           appBar: AppBar(
//             automaticallyImplyLeading: false,
//             backgroundColor: Colors.transparent,
//             title: Row(
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back_ios,
//                     size: 20,
//                   ),
//                   onPressed: () {
//                     _onBackPressed();
//                   },
//                 ),
//                 Text(
//                   "Record Transcript",
//                   style:
//                   GoogleFonts.karla(fontSize: 16, fontWeight: FontWeight.w700),
//                 ),
//               ],
//             ),
//           ),
//           body: Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Stack(
//               children: [
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     if (_isProcessing)
//                       Padding(
//                         padding: EdgeInsets.symmetric(vertical: mq.height * 0.02),
//                         child: LinearProgressIndicator(),
//                       ),
//                     Center(
//                       child: Padding(
//                         padding: EdgeInsets.all(mq.width * 0.025),
//                         child: Container(
//                           width: double.infinity,
//                           height: mq.height * 0.2,
//                           decoration: BoxDecoration(
//                             color: Color.fromRGBO(220, 236, 235, 1.0),
//                             borderRadius: BorderRadius.all(
//                               Radius.circular(mq.width * 0.03),
//                             ),
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//
//                               Text(
//                                 _remainingTime > 0
//                                     ? '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
//                                     : 'Time is up!',
//                                 style: GoogleFonts.karla(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               SizedBox(height: mq.height * 0.015),
//
//                               Image.asset(
//                                 'assets1/audioWave.gif',
//                                 fit: BoxFit.cover,
//                                 height: mq.height * 0.12,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     Text("Final text: ${appState.finalRecognizedText}",style: TextStyle(fontSize: 12),),
//
//                     SizedBox(height: mq.height * 0.25),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.ButtonColor2,
//                             shape: BoxShape.circle, // Circular shape
//                           ),
//                           padding: EdgeInsets.all(mq.width *
//                               0.02), // Padding for the icon inside the circle
//                           child: IconButton(
//                             icon: Icon(
//                               Icons.restart_alt,
//                               color: Colors.white,
//                             ),
//                             iconSize: mq.width * 0.08,
//                             onPressed: () {
//                               _onRestartPressed();
//                             },
//                           ),
//                         ),
//                         SizedBox(
//                           width: 30,
//                         ),
//
//                         Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.ButtonColor2,
//                             shape: BoxShape.circle,
//                           ),
//                           padding: EdgeInsets.all(mq.width * 0.02),
//                           child:
//                           // _buildRecordingButton(),
//
//                           IconButton(
//                               icon: Icon(
//                                 // isPaused ? Icons.stop : Icons.play_arrow,
//                                 Icons.stop,
//                                 color: Colors.white,
//                               ),
//                               iconSize: mq.width * 0.08,
//                               // onPressed: () async {
//                               //   widget.controller.stopStt();
//                               //
//                               //   // Debug log to check the value of finalRecognizedText
//                               //   print('Final Recognized Text: "${appState.finalRecognizedText}"');
//                               //   print('Is Final Recognized Text Empty: ${appState.finalRecognizedText.trim().isEmpty}');
//                               //
//                               //   if (appState.finalRecognizedText.trim().isEmpty) {
//                               //     // Debug log to confirm the condition is met
//                               //     print('Navigating to RecordView');
//                               //
//                               //     // Navigate to RecordView
//                               //     appState.navigateToRecordingPage();
//                               //   } else {
//                               //     await _sendFormattedTextToTranscribePage(appState.finalRecognizedText);
//                               //     appState.clearFinalRecognizedText();
//                               //   }
//                               // }
//
//                               onPressed: () async {
//                                 widget.controller.stopStt();
//                                 print('Final Recognized Text: "${appState.finalRecognizedText}"');
//                                 print('Is Final Recognized Text Empty: ${appState.finalRecognizedText.trim().isEmpty}');
//                                 await _sendFormattedTextToTranscribePage(appState.finalRecognizedText);
//                                 appState.clearFinalRecognizedText();
//                               }
//
//                           ),
//                         )
//                       ],
//                     ),
//                   ],
//                 ),
//
//                 if (_isLoading)
//                   Center(
//                     child: Stack(
//                       children: [
//                         Container(
//                           color: Colors.white,
//                         ),
//                         Center(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: mq.width * 0.04,
//                                 vertical: mq.height * 0.1),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Container(
//                                     height: 120,
//                                     width: 120,
//                                     child:
//                                     Image.asset("assets1/Sorting-Center.png")),
//                                 SizedBox(height: mq.height * 0.03),
//                                 Container(
//                                   height: 16,
//                                   width: 180,
//                                   child: LinearProgressIndicator(
//                                     color: Color.fromRGBO(81, 160, 155, 1.0),
//                                     backgroundColor: Colors.grey[200],
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                 ),
//                                 SizedBox(height: mq.height * 0.03),
//                                 Padding(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: mq.width * 0.05),
//                                   child: Text(
//                                     'Please wait a moment while we prepare the polished transcript',
//                                     style: GoogleFonts.karla(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w400,
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//               ],
//             ),
//           ),
//         ),
//       );
//   }
// }
//
//
//
//
