import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:oscar_stt/ui/views/record/record_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../CombinedScreenProvider.dart';
import '../auth/login_view.dart';
import '../nointernet.dart';
import 'dart:async';

class TranscribeResult extends StatefulWidget {
  final String transcribedText;
  final String title_text;
  final String unformattedText;
  final VoidCallback? onDelete;
  final String tokenid;
  final bool isEmptyInput;

  const TranscribeResult(
      {Key? key,
        required this.transcribedText,
        this.onDelete,
        required this.tokenid,
        required this.isEmptyInput,
        required this.unformattedText,
        required this.title_text,
      }) : super(key: key);

  @override
  State<TranscribeResult> createState() => _TranscribeResultState();
}
class _TranscribeResultState extends State<TranscribeResult>  with SingleTickerProviderStateMixin{
  late TextEditingController _textController;
  late TextEditingController _text_titleController;
  late TextEditingController _notFormattedText;
  late TabController _tabController;
  late final Stream<ConnectivityResult> _connectivityStream;
  String? responseDate;
  String? displayedDate;
  final Connectivity _connectivity = Connectivity();


  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.transcribedText);
    _notFormattedText = TextEditingController(text: widget.unformattedText);
    _text_titleController = TextEditingController(text: widget.title_text);
    _tabController = TabController(length: 2, vsync: this);
    _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
    _monitorInternet();
  }


  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        if (mounted){
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => NoInternetScreen(),
        ));}
      }
    });
  }

  Future<void> _deleteTranscription(BuildContext context) async {
    widget.onDelete!();
    Navigator.pop(context, 'Transcription deleted');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transcription deleted')),
    );}

  void _showErrorDialog(BuildContext context, String errorMessage) {
    var mq = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                8.0), // Square shape with slightly rounded corners
          ),
          title: const Text('Oops! an error occured',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              )),
          content: Text(errorMessage,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: mq.width * 0.04,
                color: Colors.black,
              )), // Display error message dynamically
          actions: [
            TextButton(
              onPressed: () {
                if(mounted){
                Navigator.of(context).pop();} // Close the dialog
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

  void _handleBack() {
    if(mounted){
    Navigator.pop(context, 'show_popup');}
  }

  void checkInput({required bool isEmptyInput}) {
    if (isEmptyInput) {
      print("Input is empty.");
    } else {
      print("Input is provided.");
    }
  }

  void _shareText() {
    try {
      Share.share(_textController.text);
      print('Text shared successfully');
    } catch (e) {
      print('Error sharing text: $e');
    }
  }


  // Future<void> _deleteTranscription(BuildContext context) async {
  //   widget.onDelete!(); // Perform the delete operation
  //   Navigator.pop(context, 'Transcription deleted');
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('Transcription deleted')),
  //   );}



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
          'title': _text_titleController.text ,
        }),
      );
      if (response.statusCode == 201) {
        print('Transcription successfully sent: ${response.statusCode}');
        final headerDate = response.headers['date'];
        if (responseDate != null) {
          displayedDate = _formatDate(responseDate!);
          setState(() {});
        }
        else {
          print('Date header not found');
        }
        if(mounted){
        Navigator.pop(context, 'Saved transcription');}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved transcription')),
        );
      }
      else if (response.statusCode == 401) {
        print(' Invalid token: ${response.statusCode}');
        showDialog(
          context: context,
          barrierDismissible:
          false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Session Expired'),
              content: Text('Your token is expired and you are logged out.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    if(mounted){
                    Navigator.of(context).pop();}

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
    // bool isInputEmpty = widget.unformattedText != widget.unformattedText.trim().isEmpty;

    bool isInputEmpty = widget.unformattedText.trim().isEmpty; // Corrected condition

    // bool isInputEmpty = widget.unformattedText != 'Listening for speech...' ;
    // final appState = Provider.of<AppState>(context);

    print("Unformatted Text: '${widget.unformattedText}'");
    print("Is Input Empty: $isInputEmpty");

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   appState.navigateToRecordingPage(); // Navigate to RecordView
    // });
    // final formattedDate =
    // _formatDate(response['createdAt']);
    // final formattedDate =
    // _formatDate(transcribedText['createdAt']);
    if (!isInputEmpty){
      return WillPopScope(
        onWillPop: () async {
          // Provider.of<AppState>(context, listen: false).navigateToHomePage();
          return true; // Prevent default back navigation
        },
        child: Scaffold(
          backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
          appBar: AppBar(
            scrolledUnderElevation: 0.0,
            automaticallyImplyLeading: false,
            elevation: 0,
            leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, size: mq.width * 0.04),
                onPressed: _handleBack

                  // appState.navigateToHomePage();
                ),
            backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF51A09B), // Custom indicator color
              indicatorWeight: 4.0,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 20.0), // Padding
              labelColor: const Color(0xFF51A09B), // Active tab text color
              unselectedLabelColor:
              const Color(0xFF6E6E6E), // Inactive tab text color
              labelStyle: GoogleFonts.karla(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.karla(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(
                  text: "Polished Text",
                ),
                Tab(text: "Original Text"),
              ],
            ),),
          body: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text_titleController.text,
                        style: GoogleFonts.spectral(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.karla(fontSize: 16,fontWeight: FontWeight.w400,
                          color: Color.fromRGBO(110, 110, 110, 1.0),
                          ),
                        
                        ),
                      SizedBox(height: 10,),
                      Text(
                        // _textController.text,
                        widget.transcribedText == null
                            ? 'No formatted text available'
                            : widget.transcribedText!,
                        style: GoogleFonts.karla(
                          fontSize: 16,
                          color: const Color(0xFF6E6E6E),
                          fontWeight: FontWeight.w400,),),],),),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
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
                        color: const Color(0xFF6E6E6E),
                        fontWeight: FontWeight.w400,),),],),),],),
          bottomSheet: _buildFullInputBottomSheet(context),
        ),
      );
    }else{
      var mq = MediaQuery.of(context).size;
      // final appState = Provider.of<AppState>(context);

      return Scaffold(
        backgroundColor:Color(0xFFEEF6F5),
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
                  if(mounted){
                  Navigator.pop(context);}

                  // appState.navigateToHomePage();

                },
              ),],),),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets1/Marketing 3 1.svg',
                width: 120.31,
                height: 90.31,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 30),
                child: Text(
                  "It seems the mic was not working or no words were spoken",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.karla(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4D4D4D)),),),],),),

        floatingActionButton: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.ButtonColor2,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: IconButton(
                      icon: Icon(
                        Icons.mic, // Microphone icon
                        color: Colors.white, // Icon color
                        size: 32.0, // Icon size
                      ),
                      iconSize: mq.height * 1 / 18,
                      onPressed: () async {
                        
                        print("Microphone button pressed");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordView(
                              onRecordingComplete: (String recording) {
                              },
                              tokenid: widget.tokenid,),),);
                        // appState.navigateToTranscriptionPage();
                        // Provider.of<AppState>(context, listen: false).navigateToRecordingPage(ManualSttController(context));
                      },),),),),),],),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    }
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
                          if (mounted){
                          Navigator.pop(context);
                          }
                          // Provider.of<AppState>(context, listen: false).navigateToHomePage();
                          // appState.navigateToHomePage();

                          // Navigator.of(context).pop();
                          // _deleteTranscription(widget.transcriptionId);
                          // _handleDeleteTranscription();
                          // Navigator.pop(context);
                        },
                        iconSize: 20,),
                    ],),),),

              SafeArea(
                child: GestureDetector(
                  onTap: () async {
                    await _sendTranscriptionToBackend();
                    // Provider.of<AppState>(context, listen: false).navigateToHomePage();
                  },
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
    // _connectivitySubscription.cancel();
    // _connectivitySubscription = null;
    super.dispose();
  }
}



