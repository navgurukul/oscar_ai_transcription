import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';

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
  AppState({required this.tokenid});


  bool get showHomePage => _showHomePage;
  bool get showRecordingPage => _showRecordingPage;
  bool get showTranscriptionPage => _showTranscriptionPage;

  ManualSttState get currentState => _currentState;
  String get finalRecognizedText => _finalRecognizedText;
  double get soundLevel => _soundLevel;

  String get formattedText => _formattedText;
  String get unformattedText => _unformattedText;
  String get titleText => _titleText;

  void navigateToRecordingPage() {
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

