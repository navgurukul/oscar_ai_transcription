import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/login_view.dart';
import 'package:http/http.dart' as http;
import '../nointernet.dart';
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
  final Connectivity _connectivity = Connectivity();
  late final Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer for lifecycle changes
    _sttController = ManualSttController(context); // Pass the context here
    _initializeSpeechToText();
    _checkPermissionAndStartListening(); // Check permission and start listening
    _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
    _monitorInternet();
  }

  void _initializeSpeechToText() {
    _sttController.listen(
      onListeningStateChanged: (isListening) {
        if (mounted) {
          setState(() {
          });
        }
      },
      onListeningTextChanged: (text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;});}},);

    _checkPermissionAndStartListening(); // Check permission and start listening
    _sttController.enableHapticFeedback = true;
    _sttController.localId = 'en-US';
    _sttController.clearTextOnStart = true;
    _sttController.pauseIfMuteFor = Duration(seconds: 15);

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
      // _stopListening();
      _sttController.stopStt();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // App comes back to the foreground
      print("App returned to foreground.");
    }
  }


  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        _sttController.stopStt();
        _timer?.cancel();
        // Navigate to the NoInternetScreen
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NoInternetScreen(),
        ));
      }
    });
  }

  void _startListening() {
    _sttController.pauseIfMuteFor = Duration(seconds: 15);
    _sttController.startStt();
  }

  void _stopListening() {
    _sttController.stopStt(); // Stop the manual STT
    setState(() {
      // Accumulate recognized text into _cumulativeText
      _cumulativeText += " " + _recognizedText.trim();
    });

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
              title_text: titleText,
              // date : formattedData['date'],
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
    _timer?.cancel(); // Ensure no overlapping timers
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          _stopListening();}});});}
  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    _startCountdown();
  }

  Future<void> _onBackPressed() async {
    print("BAck arrow pressed");
    _pauseTimer();
    _sttController.stopStt();
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Adjust the radius here
          ),
          backgroundColor: Colors.white,
          title:Text(
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
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(BorderSide(color: AppColors.ButtonColor2)),
                padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // Discard
              },
              child: Text('Discard',style: GoogleFonts.karla(
              fontSize: 16,
              color:AppColors.ButtonColor2,
              fontWeight: FontWeight.w400,
            ),),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.ButtonColor2),
                padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),),
              onPressed: () {
                Navigator.of(context).pop(true);
                 // Keep Recording
              },
              child: Text('Keep Recording',style: GoogleFonts.karla(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,),),),],);},);
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
    // _stopCountdown();

    bool? result = await showDialog<bool>(  // Display reset/discard dialog
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Adjust the radius here
          ),
          backgroundColor: Colors.white,
          title: Text('Reset Recording'),
          content: Text('Curent recording will be erased an a new one will be started '),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(BorderSide(color: AppColors.ButtonColor2)),
                padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // Discard
              },
              child: Text('Discard',style: GoogleFonts.karla(
              fontSize: 16,
              color:AppColors.ButtonColor2,
              fontWeight: FontWeight.w400,
            ),),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.ButtonColor2),
                side: WidgetStateProperty.all(BorderSide(color: AppColors.ButtonColor2)),
                padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Reset
              },
              child: Text('Reset',style: GoogleFonts.karla(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,),),),],);},);
    if (result == true) {
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
    _sttController.stopStt(); // Ensure recording is stopped before disposing
    _sttController.dispose();
    _pauseTimer();
    // _connectivitySubscription.cancel();

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
        "device_tag": '3', // Static device tag, adjust if needed
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
        final formattedDate = responseData["data"]['createdAt']??'';

        return {
          "title": formattedTitle,
          "transcript": formattedText,
          'date': formattedDate
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
        title: Text('Error', style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),),
        content: Text(message, style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: TextStyle(
              // fontWeight: FontWeight.bold,
              color: Colors.white,
            ),),
            style: ButtonStyle(
                backgroundColor:
                WidgetStateProperty.all(AppColors.ButtonColor2),
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),),),),],),);}
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
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),),),),],);},);}
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    return
      Scaffold(
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
                          _onRestartPressed();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 30,
                    ),

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
                        onPressed: _stopListening,
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