import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/login_view.dart';
import 'package:http/http.dart' as http;
import '../transcribe/transcribe_view.dart';


class RecordView extends StatefulWidget {
  final Function(String) onRecordingComplete;
  final String tokenid;

  RecordView({
    required this.onRecordingComplete,
    required this.tokenid,
  });

  @override
  _RecordViewState createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> with WidgetsBindingObserver {
  late ManualSttController _sttController;
  String _recognizedText = "Listening for speech...";
  String _cumulativeText = ""; // Store all recognized text cumulatively
  int _remainingTime = 180; // 3 minutes in seconds
  Timer? _timer;
  bool _isLoading = false;
  bool _isListening = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer for lifecycle changes
    _sttController = ManualSttController(context); // Pass the context here
    _initializeSpeechToText();
    _checkPermissionAndStartListening(); // Check permission and start listening
  }

  void _initializeSpeechToText() {
    _sttController.listen(
      onListeningStateChanged: (isListening) {
       if (mounted) {
         setState(() {
           _isListening = isListening == ManualSttState.listening;
         });
       }
      },
      onListeningTextChanged: (text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
          });
        }
      },
    );

    _checkPermissionAndStartListening(); // Check permission and start listening
    _sttController.enableHapticFeedback = true;
    _sttController.localId = 'en-US';
    _sttController.clearTextOnStart = true;

    // Set the pause time when mute is detected
    _sttController.pauseIfMuteFor = Duration(seconds: 20);
  }

  Future<void> _checkPermissionAndStartListening() async {
    try {
      // Request microphone permission
      final PermissionStatus status = await Permission.microphone.request();

      if (status.isGranted) {
        print('Microphone permission granted. Initializing STT...');
        _startListening(); // Start recording if permission is granted
        _startCountdown(); // Start the timer only after recording begins
      } else if (status.isDenied) {
        print('Microphone permission denied.');
        _stopCountdown(); // Stop the timer if permission is denied
      } else if (status.isPermanentlyDenied) {
        print('Microphone permission permanently denied. Please enable it in settings.');
        openAppSettings(); // Redirect user to app settings
        _stopCountdown(); // Stop the timer if permission is denied
      }
    } catch (e) {
      print('Error during permission check: $e');
      _stopCountdown(); // Stop the timer in case of any error
    }
  }
  void _stopCountdown() {
    _timer?.cancel(); // Cancel the timer
    _remainingTime = 180; // Reset the timer to its initial value
    setState(() {}); // Update the UI
  }

  // Listen for app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App goes to the background
      print("App moved to background. Stopping recording.");
      _stopListening();
    } else if (state == AppLifecycleState.resumed) {
      // App comes back to the foreground
      print("App returned to foreground.");
    }
  }

  void _startListening() {
    _sttController.pauseIfMuteFor = Duration(seconds: 20);
    _sttController.startStt();
  }

  void _stopListening() {
    _sttController.stopStt(); // Stop the manual STT
    setState(() {
      // Accumulate recognized text into _cumulativeText
      _cumulativeText += " " + _recognizedText.trim();
    });

    // Send the transcription to the backend API for formatting and then navigate to the TranscribeResult page
    _sendFormattedTextToTranscribePage(_cumulativeText.trim());
  }

  Future<void> _sendFormattedTextToTranscribePage(String transcriptionToSend) async {
    try {
      bool isEmptyInput = transcriptionToSend.isEmpty;

      // Format the transcription text
      Map<String, String>? formattedData = await _formatText(transcriptionToSend);

      if (formattedData != null) {
        // Extract the formatted transcription and title
        String formattedText = formattedData["transcript"] ?? transcriptionToSend;
        String titleText = formattedData["title"] ?? 'Untitled';

        // Navigate to the TranscribeResult page with the formatted text
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TranscribeResult(
              transcribedText: formattedText,
              unformattedText: transcriptionToSend,
              isEmptyInput: isEmptyInput,
              onDelete: () {
                widget.onRecordingComplete(''); // Reset recording completion
              },
              tokenid: widget.tokenid,
              title_text: titleText, // Send formatted title
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


  void _startCountdown() {
    _timer?.cancel(); // Ensuring here no overlapping timers

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          _stopListening();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    _startCountdown();
  }

  Future<void> _onBackPressed() async {
    _sttController.stopStt();
    _pauseTimer(); // Pause the timer

    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to keep recording or discard?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Discard
              },
              child: Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Keep Recording
              },
              child: Text('Keep Recording'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _cumulativeText += " " + _recognizedText.trim(); // Save previous session's text
        _recognizedText = ""; // Clear for the new session
      });
      _startListening(); // Resume recording
      _resumeTimer(); // Resume the timer
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onRestartPressed() async {
    _pauseTimer(); // Pause the timer
    _sttController.stopStt(); // Stop the recording

    bool? result = await showDialog<bool>(  // Display reset/discard dialog
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Restart Recording'),
          content: Text('Do you want to reset or discard the current recording?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Discard
              },
              child: Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Reset
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // Reset option selected
      setState(() {
        // Start a new recording session without appending the old text
        _recognizedText = ""; // Clear the current recognized text
        _cumulativeText = ""; // Clear cumulative text as well (no old text saved)
        _remainingTime = 180; // Reset the timer
      });

      // Start a new recording session
      _sttController.startStt(); // Start a new recording with manual_stt
      _startCountdown(); // Restart the timer
    } else {
      // Discard option selected
      setState(() {
        // Append the old recognized text to cumulativeText before starting new recording
        _cumulativeText += " " + _recognizedText.trim(); // Save old text
        _recognizedText = ""; // Clear current recognized text for new recording
      });

      // Resume the timer
      _resumeTimer();
      // Continue the recording session with manual_stt
      _sttController.startStt(); // Continue recording with manual_stt
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop observing lifecycle changes
    _sttController.stopStt();
    _sttController.dispose();
    _pauseTimer();
    super.dispose();
  }

  Future<Map<String, String>?> _formatText(String speechText) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    const String apiUrl = "https://dev-oscar.merakilearn.org/api/v1/optimize/optimize-text";

    try {
      // Prepare the POST request body
      final Map<String, String> body = {
        "user_input": speechText,
        "device_tag": '3', // Static device tag
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

      // Handle the response
      if (response.statusCode == 201) {
        print('Request successful');
        final responseData = jsonDecode(response.body);

        // Extract formatted text and title
        final formattedText = responseData["data"]["transcript"] ?? speechText;
        final formattedTitle = responseData["data"]["title"] ?? 'Untitled';
        return {
          "title": formattedTitle,
          "transcript": formattedText,
        };
      } else if (response.statusCode == 401) {
        print('Unauthorized');
        _showSessionExpiredDialog();
      } else if (response.statusCode == 429) {
        print('Too many requests or daily quota exceeded');
        _showErrorDialog( 'Too many requests or daily quota exceeded');
      } else if (response.statusCode == 500) {
        print('Internal Server Error.');
        _showErrorDialog(
            'The server encountered an error while processing your request');
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        final responseData = jsonDecode(response.body);
        _showErrorDialog( responseData['message'] ?? 'An error occurred');
      }
    } catch (e) {
      print("Error making POST request: $e");
      _showErrorDialog( 'An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
    return null;
  }
  void _showErrorDialog(String message) {
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

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          title: Text(
            'Session Expired',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Your token is expired, and you have been logged out.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await GoogleSignIn().signOut();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('isLoggedIn');

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
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    return
      Scaffold(
        backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: _onBackPressed,
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(mq.width * 0.025),
                child: Container(
                  width: double.infinity,
                  height: mq.height * 0.2,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(81, 160, 155, 1.0),
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
                        style: TextStyle(
                          fontSize: mq.width * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
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
            SizedBox(height: mq.height * 0.1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Restart button
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(81, 160, 155, 1.0),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(mq.width * 0.02),
                  child: IconButton(
                    icon: Icon(
                      Icons.restart_alt,
                      color: Colors.white,
                    ),
                    iconSize: mq.width * 0.08,
                    onPressed: _onRestartPressed,
                  ),
                ),
                // Stop button
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(81, 160, 155, 1.0),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(mq.width * 0.02),
                  child: IconButton(
                    icon: Icon(
                      Icons.stop,
                      color: Colors.white,
                    ),
                    iconSize: mq.width * 0.08,
                    onPressed: _stopListening,
                  ),
                ),
              ],
            ),

            if (_isLoading)
              Stack(
                children: [
                  // Blurred background
                  BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 5.0,
                        sigmaY: 5.0), // Can adjust the blur strength as needed
                    child: Container(
                      color: Colors.black.withOpacity(
                          0.2), // Slightly tinted background to improve readability
                    ),
                  ),
                  // Custom loading UI
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
                          SizedBox(height: mq.height * 0.03),
                          LinearProgressIndicator(
                            color: Color.fromRGBO(81, 160, 155, 1.0),
                            backgroundColor: Colors.grey[200],
                            minHeight: 30,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          SizedBox(height: mq.height * 0.03),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: mq.width * 0.05),
                            child: Text(
                              'Please wait a moment while we prepare the text for you',
                              style: TextStyle(
                                fontSize: mq.width * 0.04,
                                fontWeight: FontWeight.normal,
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

          ],
        ),
      );
  }
}
