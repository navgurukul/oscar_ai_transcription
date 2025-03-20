


import 'package:flutter/material.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:oscar_stt/ui/views/record/record_view.dart';
import 'package:oscar_stt/ui/views/transcribe/transcribe_view.dart';
import 'package:provider/provider.dart';
// import 'package:testing_oscar/core/viewmodels/get_api.dart';
// import 'package:testing_oscar/ui/views/record/record_view.dart';
// import 'package:testing_oscar/ui/views/transcribe/transcribe_view.dart';
import 'CombinedScreenProvider.dart';
import 'home/home_view.dart';

class CombinedPage extends StatelessWidget {
  final String profileName;
  final String profilePicUrl;
  final String tokenid;
  final ManualSttController controller;

  const CombinedPage({
    Key? key,
    required this.profileName,
    required this.profilePicUrl,
    required this.tokenid,
    required this.controller
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    _setupController(appState);

    return Scaffold(
      body: Stack(
        children: [
          // Home Page
          Visibility(
            visible: appState.showHomePage,
            child: HomePage(
              profileName: profileName,
              profilePicUrl: profilePicUrl,
              tokenid: tokenid,
              transcribedata: '', controller: controller,  // Pass empty or default value
            ),
          ),

          // Recording Page
          Visibility(
            visible: appState.showRecordingPage,
            child: RecordView(controller: controller, tokenid: tokenid,),
          ),

          // Transcription Page
          Visibility(
            visible: appState.showTranscriptionPage,
            child:
            TranscribeResult(
              tokenid: tokenid,
              transcribedText: appState.formattedText, // Pass finalRecognizedText
              unformattedText: appState.unformattedText, // Pass the same text for now
              onDelete: () {
                // Handle delete logic if needed
              },
              title_text: appState.titleText, controller: controller, transcriptionId: '',
            ),
            // TranscriptionsPage(tokenid: tokenid),
          ),
        ],
      ),
    );
  }
  void _setupController(AppState appState) {
    controller.listen(
      onListeningStateChanged: (state) {
        appState.updateRecordingState(state);
      },
      onListeningTextChanged: (text) {
        appState.updateRecognizedText(text);
      },
      onSoundLevelChanged: (level) {
        appState.updateSoundLevel(level);
      },
    );
  }



}

