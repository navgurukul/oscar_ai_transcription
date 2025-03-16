import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:do_not_disturb/do_not_disturb_plugin.dart';
import 'package:do_not_disturb/types.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
<<<<<<< HEAD
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:oscar_stt/ui/detailpage.dart';
import 'package:oscar_stt/ui/views/nointernet.dart';
import 'package:oscar_stt/ui/views/transcribe/transcribe_view.dart';
=======
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:testing_oscar/core/viewmodels/get_api.dart';

import '../../../core/constants/app_colors.dart';
>>>>>>> transcription_list
import '../../../core/viewmodels/api_service.dart';
// import '../../../detailpage.dart';
import '../../detailpage.dart';
import '../../shared/styles/text_style.dart';
import '../CombinedScreenProvider.dart';
import '../nointernet.dart';
import '../profile/profile_view.dart';
import '../record/record_view.dart';
import 'dart:async';

<<<<<<< HEAD
=======
import '../transcribe/transcribe_view.dart';


>>>>>>> transcription_list
class HomePage extends StatefulWidget {
  final String profileName;
  final String profilePicUrl;
  final String transcribedata;
  final String tokenid;
  final ManualSttController controller;


  const HomePage({
    Key? key,
    required this.transcribedata,
    required this.profileName,
    required this.profilePicUrl,
    required this.tokenid, required this.controller,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _transcriptionsFuture;
  final Connectivity _connectivity = Connectivity();
  late final Stream<ConnectivityResult> _connectivityStream;
  final dndPlugin = DoNotDisturbPlugin();
  bool isListening = false;
<<<<<<< HEAD


  late final Stream<ConnectivityResult> _connectivityStream;
=======
  List<Map<String, dynamic>> _currentTranscriptions = [];
>>>>>>> transcription_list

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transcriptionsFuture = ApiService().fetchTranscriptions(widget.tokenid);
    _refreshData();
  }

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _connectivityStream =
        _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
=======
    // _transcriptionsFuture = ApiService().fetchTranscriptions(widget.tokenid);
    // Provider.of<AppState>(context, listen: false).monitorInternet(context);
    _connectivityStream = _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
>>>>>>> transcription_list
    _monitorInternet();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.settings.arguments == true) {
        _showRefreshAlertDialog();
        _refreshData();
      }
    });
    // _refreshData();
  }

<<<<<<< HEAD
  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NoInternetScreen(),
        ));
      }
    });
  }

  void dispose() {
    super.dispose();
  }

  Future<void> _enableDndMode() async {
    if (await dndPlugin.isNotificationPolicyAccessGranted()) {
      await dndPlugin.setInterruptionFilter(InterruptionFilter.priority);
      print("DND mode enabled.");
    } else {
      print("DND permission not granted.");
      await dndPlugin.openNotificationPolicyAccessSettings();
    }
  }

  Future<void> _disableDndMode() async {
    if (await dndPlugin.isNotificationPolicyAccessGranted()) {
      await dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      print("DND mode disabled.");
    } else {
      print("DND permission not granted.");
    }
  }

=======
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("App resumed. Checking DND permission again.");
      _checkDndPermission();
    } else if (state == AppLifecycleState.paused) {
      print("App moved to background.");
      // Stop recording if needed
      if (isListening) {
        widget.controller.stopStt();
      }
    }
  }
>>>>>>> transcription_list
  void _showRefreshAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notice'),
          content: Text('Refresh page for new Transcription'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _checkDndPermission() async {
    bool isDndEnabled = await dndPlugin.isNotificationPolicyAccessGranted();

    if (!isDndEnabled) {
      print("DND permission not granted. Redirecting to settings...");
      await dndPlugin.openNotificationPolicyAccessSettings();

      // Wait for a few seconds before checking again (gives user time to enable)
      await Future.delayed(Duration(seconds: 2));

      // Recheck DND permission after returning from settings
      isDndEnabled = await dndPlugin.isNotificationPolicyAccessGranted();
      if (!isDndEnabled) {
        print("DND permission still not granted after returning from settings.");
        return;
      }
    }

    print("DND permission is granted.");
  }

  Future<void> _enableDndMode() async {
    if (await dndPlugin.isNotificationPolicyAccessGranted()) {
      // Set DND to priority mode
      await dndPlugin.setInterruptionFilter(InterruptionFilter.priority);
      print("DND mode enabled.");
    } else {
      print("DND permission not granted. Requesting permission...");
      await dndPlugin.openNotificationPolicyAccessSettings();

      // Wait for the user to grant permission
      await Future.delayed(Duration(seconds: 2)); // Give some time for settings to open

      // Try enabling DND again after returning from settings
      if (await dndPlugin.isNotificationPolicyAccessGranted()) {
        await dndPlugin.setInterruptionFilter(InterruptionFilter.priority);
        print("DND mode enabled after granting permission.");
      } else {
        print("DND permission still not granted.");
      }
    }
  }

  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        widget.controller.stopStt();

        // Navigate to the NoInternetScreen
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => NoInternetScreen(),
        ));
      }
    });
  }
  void _deleteTranscription(String transcriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'https://dev-oscar.merakilearn.org/api/v1/transcriptions/$transcriptionId'),
        headers: {'Authorization': 'Bearer ${widget.tokenid}'},
      );

      if (response.statusCode == 200) {
        print('deleted successfully');
        setState(() {
<<<<<<< HEAD
          _transcriptionsFuture = _fetchTranscriptions();
=======
          _transcriptionsFuture = fetchTranscriptions(); // Refresh the data
>>>>>>> transcription_list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcription deleted'),
          ),
        );
      } else if (response.statusCode == 400) {
        print('Bad Request');
        _showErrorDialog(
            context, 'Failed to delete transcription due to Bad Request');
      } else if (response.statusCode == 404) {
        print('Transcription not found');
        _showErrorDialog(
            context, 'Failed to delete due to Transcription not found');
      } else if (response.statusCode == 500) {
        print('Internal server error ');
        _showErrorDialog(context,
            'Failed to delete transcription due to Internal server error ');
      } else {
        _showErrorDialog(context, 'Failed to delete transcription');
        throw Exception('Failed to delete transcription');
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog(context, '$e');
    }
  }
<<<<<<< HEAD

  Future<List<Map<String, dynamic>>> _fetchTranscriptions() async {
    final response = await http.get(
      Uri.parse('https://dev-oscar.merakilearn.org/api/v1/transcriptions'),
      headers: {'Authorization': 'Bearer ${widget.tokenid}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      _showErrorDialog(context, data['message']);
      return data['message'];
    } else if (response.statusCode == 404) {
      final data = jsonDecode(response.body);
      _showErrorDialog(context, data['message']);
      return data['message'];
    } else if (response.statusCode == 500) {
      final data = jsonDecode(response.body);
      _showErrorDialog(context, data['message']);
      return data['message'];
    } else if (response.statusCode == 401) {
      final data = jsonDecode(response.body);
      _showErrorDialog(context, data['message']);
      return data['message'];
    } else {
      _showErrorDialog(context, 'Failed to load transcription');
      throw Exception('Failed to load transcriptions');
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('MMM dd, yyyy').format(date);
  }

=======
>>>>>>> transcription_list
  void _showErrorDialog(BuildContext context, String errorMessage) {
    var mq = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                8.0),
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
              )),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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


  Future<List<Map<String, dynamic>>> fetchTranscriptions() async {
    try {
      final response = await http.get(
        Uri.parse('https://dev-oscar.merakilearn.org/api/v1/transcriptions'),
        headers: {'Authorization': 'Bearer ${widget.tokenid}'},
      );

      print("API Response Status Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load transcriptions. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching transcriptions: $e");
      throw Exception('Failed to load transcriptions');
    }
  }

  Future<void> _refreshData() async {
    try {
      final newTranscriptions = await ApiService().fetchTranscriptions(widget.tokenid);
      // print("New transcriptions: $newTranscriptions");

      if (mounted) {
        setState(() {
          _transcriptionsFuture = Future.value(newTranscriptions);
          _currentTranscriptions = newTranscriptions;
        });
      }

      if (_currentTranscriptions.length < newTranscriptions.length) {
        _showNewTranscriptionSnackBar();
      }
    } catch (e) {
      print("Error fetching transcriptions: $e");
      if (mounted) {
        setState(() {
          // Handle error state if needed
        });
      }
    }
  }
  void _showNewTranscriptionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New transcription added'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('MMM dd, yyyy').format(date); // Formats to Jan 10, 2025
  }


  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
<<<<<<< HEAD
=======
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.75;
>>>>>>> transcription_list

    final appState = Provider.of<AppState>(context);


    return WillPopScope(
      onWillPop: () async {
        await SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0.0,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets1/Frame 31584.svg',
                    width: 98,
                    height: 32,
                  ),
                  SizedBox(width: 5,),
                ],
              ),
              IconButton(
                icon: CircleAvatar(
                  backgroundImage: widget.profilePicUrl != null &&
                      widget.profilePicUrl!.isNotEmpty
                      ? NetworkImage(widget.profilePicUrl!)
                      : null,
                  radius: mq.width * 0.04,
                  backgroundColor: Colors.blue,
                  child: widget.profilePicUrl == null ||
                      widget.profilePicUrl!.isEmpty
                      ? Text(
                    widget.profileName.isNotEmpty
                        ? widget.profileName[0].toUpperCase()
                        : '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: mq.width * 0.04,
                    ),
                  )
                      : null,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen(
                          profileName: widget.profileName,
                          profilePicUrl: widget.profilePicUrl))
                  );
                },)],),
        ),
        body:
        RefreshIndicator(
          onRefresh: _refreshData,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _transcriptionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SingleChildScrollView(
                  physics:
<<<<<<< HEAD
                      AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height:
                        mq.height - kToolbarHeight,
=======
                  AlwaysScrollableScrollPhysics(), // Ensures scroll even when empty
                  child: Container(
                    height:
                    mq.height - kToolbarHeight, // Full height minus AppBar
>>>>>>> transcription_list
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center,
                        crossAxisAlignment: CrossAxisAlignment
                            .center,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.all(mq.width * 0.05),
                              child: Text(
                                "My Transcripts (0)",
                                style: TextStyles.defaultTextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: mq.height * 0.20),
                          Image.asset(
                            'assets1/Group-12307.png',
                            width: 118.31,
                            height: 118.31,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 80.0, vertical: 30),
                            child: Text(
                              "Your first thought could be the best one - let it flow",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.karla(
                                fontSize: 16,
<<<<<<< HEAD
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
=======
                                fontWeight: FontWeight.w400,),),), Spacer(),],),),),);
>>>>>>> transcription_list
              } else {
                List<Map<String, dynamic>> transcriptions = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(mq.width * 0.05),
                      child: Text(
                        "My Transcripts (${transcriptions.length})",
                        style: GoogleFonts.karla(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          scrollbarTheme: ScrollbarThemeData(
                            thumbColor:
                            WidgetStateProperty.all(AppColors.ButtonColor2),
                            trackColor: WidgetStateProperty.all(Colors.white),
                            trackVisibility: WidgetStateProperty.all(true),
                            thumbVisibility: WidgetStateProperty.all(true),
                            thickness: WidgetStateProperty.all(10.0),
                            radius: Radius.circular(80.0),
                          ),
                        ),

                        child: ListView.builder(
<<<<<<< HEAD
                          padding: EdgeInsets.symmetric(
                              horizontal: mq.width *
                                  0.05),
                          itemCount: transcriptions.length,
                          itemBuilder: (context, index) {
                            final transcription =
                                transcriptions.reversed.toList()[index];
                            final formattedDate =
                                _formatDate(transcription['createdAt']);
=======
                          padding: EdgeInsets.symmetric( horizontal: mq.width * 0.05), // Added padding on left and right
                          itemCount: transcriptions.length,
                          itemBuilder: (context, index) {
                            final transcription =
                            transcriptions.reversed.toList()[index];
                            final formattedDate = _formatDate(transcription['createdAt']);
                            // Determine maxLines based on the text length
>>>>>>> transcription_list
                            int maxLines;
                            if (transcription.length <= 50) {
                              maxLines = 1;
                            } else if (transcription.length <= 150) {
                              maxLines = 2;
                            } else {
                              maxLines = 5;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Color(0xFFEEF6F5),
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
<<<<<<< HEAD
                                            CrossAxisAlignment.start,
=======
                                        CrossAxisAlignment.start,
>>>>>>> transcription_list
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      Detailpage(
                                                        transcribedText:
                                                        transcription[
                                                        'transcribedText'],
                                                        id1: transcription['id']
                                                            .toString(),
                                                        date: formattedDate,
                                                        unformattedText:
                                                        transcription[
<<<<<<< HEAD
                                                            'userTextInput'],
                                                    title:
                                                        transcription['title'],
                                                    tokenid: widget.tokenid,
                                                  ),
=======
                                                        'userTextInput'],
                                                        title:
                                                        transcription['title'],
                                                        tokenid: widget.tokenid,

                                                      ),
>>>>>>> transcription_list
                                                ),
                                              );
                                            },
                                            child: Container(
<<<<<<< HEAD
=======
                                              //height: 200.0,
>>>>>>> transcription_list
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
<<<<<<< HEAD
                                                children: [
                                                  Text(
                                                    transcription['title'] ??
                                                        'Untitled',
                                                    style: GoogleFonts.karla(
                                                      fontSize: 16.0,
                                                      fontWeight:
=======
                                                    children: [
                                                      Text(
                                                        transcription['title'] ??
                                                            'Untitled', // Display the title or fallback text
                                                        style: GoogleFonts.karla(
                                                          fontSize: 16.0,
                                                          fontWeight:
>>>>>>> transcription_list
                                                          FontWeight.w700,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        transcription[
                                                        'transcribedText'],
<<<<<<< HEAD
                                                    maxLines:3,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: GoogleFonts.karla(
                                                        fontSize: 14.0,
                                                        fontWeight:
=======
                                                        maxLines: maxLines, // Dynamic number of lines
                                                        overflow: TextOverflow.ellipsis, // Truncate extra text
                                                        style: GoogleFonts.karla(
                                                            fontSize: 14.0,
                                                            fontWeight:
>>>>>>> transcription_list
                                                            FontWeight.w400,
                                                            color: AppColors.Text2),
                                                      ),
                                                      SizedBox(
                                                        height: 10,
                                                      ),
                                                      Container(
                                                        height: 30,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                Clipboard.setData(
                                                                  ClipboardData(
                                                                      text: transcription[
                                                                      'transcribedText']),
                                                                );
                                                                ScaffoldMessenger
                                                                    .of(context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content: Text(
                                                                          'Copied to clipboard')),
                                                                );
                                                              },
                                                              child: Icon(
                                                                Icons.copy,
                                                                color: const Color(
                                                                    0xFF6E6E6E),
                                                                size: 16.0,
                                                              ),
                                                            ),
                                                            Text(
                                                              formattedDate,
                                                              style:
                                                              GoogleFonts.karla(
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                FontWeight.w400,
                                                                color:
                                                                AppColors.Text3,),),],),)],),)),)],)],),),),);},),),),],);}},),),

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
<<<<<<< HEAD
                      icon: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 32.0,
                      ),
                      iconSize: mq.height * 1 / 18,
                      onPressed: () async {
                        await _enableDndMode();
                        print("Microphone button pressed");
                        final newTranscription = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context, ) => RecordView(
                              onRecordingComplete: (transcribedText) {
                                _refreshData();
                                Navigator.pop(context, true);
                                _disableDndMode();
                                setState(() {
                                  _transcriptionsFuture =
                                      _fetchTranscriptions();
                                });
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TranscribeResult(
                                      transcribedText: transcribedText,
                                      unformattedText: '',
                                      onDelete: () =>
                                          _deleteTranscription(transcribedText),
                                      tokenid: widget.tokenid, title_text: '',
                                      isEmptyInput: false,
                                    ),
                                  ),
                                );
                              },
                              tokenid: widget.tokenid,
                            ),
                          ),
                        );
                        if (newTranscription != null &&
                            newTranscription == true) {
                          _refreshData();
=======
                        icon: Icon(
                          Icons.mic, // Microphone icon
                          color: Colors.white, // Icon color
                          size: 32.0, // Icon size
                        ),
                        iconSize: mq.height * 1 / 18,
                        onPressed: () async {
                          final appState = Provider.of<AppState>(context, listen: false);
                          try {
                            // Check microphone permission only when needed
                            var status = await Permission.microphone.request();
                            if (status.isGranted) {
                              print("Microphone permission granted. Starting recording...");
                              await _checkDndPermission();
                              await _enableDndMode();
                              appState.navigateToRecordingPage();
                              await appState.refreshData();
                            } else {
                              print("Microphone permission denied. Cannot start recording.");
                            }
                          } catch (e) {
                            print('Error occurred: $e');
                          }
>>>>>>> transcription_list
                        }
                    ),
                  ),

                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }}

