import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/viewmodels/api_service.dart';
import 'nointernet.dart';

class AppState with ChangeNotifier {
  bool _showHomePage = true;
  bool _showRecordingPage = false;
  bool _showTranscriptionPage = false;

  ManualSttState _currentState = ManualSttState.stopped;
  String _finalRecognizedText = '';
  double _soundLevel = 0.0;

  String _formattedText = '';
  String _unformattedText = '';
  String _titleText = '';

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivityStream;
  // final ManualSttController controller;
  List<Map<String, dynamic>> _transcriptions = [];

  final String tokenid;
  final ManualSttController controller;
  AppState({required this.tokenid,required this.controller});


  bool get showHomePage => _showHomePage;
  bool get showRecordingPage => _showRecordingPage;
  bool get showTranscriptionPage => _showTranscriptionPage;

  ManualSttState get currentState => _currentState;
  String get finalRecognizedText => _finalRecognizedText;
  double get soundLevel => _soundLevel;

  String get formattedText => _formattedText;
  String get unformattedText => _unformattedText;
  String get titleText => _titleText;


  void navigateToRecordingPage(ManualSttController controller) {
    print("Navigating to Recording Page");
    _showHomePage = false;
    _showRecordingPage = true;
    _showTranscriptionPage = false;
    notifyListeners();
  }


  void navigateToTranscriptionPage() {
    _showHomePage = false;
    _showRecordingPage = false;
    _showTranscriptionPage = true;
    notifyListeners();
  }

  void navigateToHomePage() {
    _showHomePage = true;
    _showRecordingPage = false;
    _showTranscriptionPage = false;
    notifyListeners();
    refreshData();
  }

  Future<void> refreshData() async {
    try {
      // Fetch transcriptions from the API
      _transcriptions = await ApiService().fetchTranscriptions(tokenid);
      notifyListeners(); // Notify listeners to rebuild the UI
    } catch (e) {
      print("Error fetching transcriptions: $e");
    }
  }

  void updateRecordingState(ManualSttState state) {
    _currentState = state;
    notifyListeners();
  }

  void updateRecognizedText(String text) {
    _finalRecognizedText = text;
    notifyListeners();
  }
  void clearFinalRecognizedText() {
    _finalRecognizedText = ''; // Clear the final recognized text
    notifyListeners(); // Notify listeners to update the UI
  }

  void updateSoundLevel(double level) {
    _soundLevel = level;
    notifyListeners();
  }

  void updateFormattedText(String formattedText, String unformattedText, String titleText) {
    _formattedText = formattedText;
    _unformattedText = unformattedText;
    _titleText = titleText;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivityStream.cancel();
    super.dispose();
  }
}

/////////////////////
// Future<void> navigateToRecordingPage({bool startRecording = false}) async {
//   var status = await Permission.microphone.status;
//   if (!status.isGranted) {
//     status = await Permission.microphone.request();
//   }
//   if (status.isGranted) {
//     _showHomePage = false;
//     _showRecordingPage = true; // Show recording page
//     _showTranscriptionPage = false;
//     notifyListeners(); // Notify listeners to update the UI
//
//     if (startRecording) {
//       // Start recording after navigating to the recording page
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_currentState != ManualSttState.listening) {
//           controller.startStt(); // Start recording
//         }
//       });
//     }
//   } else {
//     print("Microphone permission denied");
//   }
// }
/////////////////////////

// Future<void> navigateToRecordingPage({bool startRecording = false}) async {
//   var status = await Permission.microphone.status;
//   if (!status.isGranted) {
//     status = await Permission.microphone.request();
//   }
//   if (status.isGranted) {
//     _showHomePage = false;
//     _showRecordingPage = true;
//     _showTranscriptionPage = false;
//     notifyListeners();
//
//     if (startRecording) {
//       // Start recording after navigating to the recording page
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_currentState != ManualSttState.listening) {
//           // Assuming you have access to the controller here
//           // If not, you need to pass the controller to AppState
//           controller.startStt(); // Start recording
//         }
//       });
//     }
//   } else {
//     print("Microphone permission denied");
//   }
// }