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
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:testing_oscar/core/viewmodels/get_api.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/viewmodels/api_service.dart';
// import '../../../detailpage.dart';
import '../../detailpage.dart';
import '../../shared/styles/text_style.dart';
import '../CombinedScreenProvider.dart';
import '../nointernet.dart';
import '../profile/profile_view.dart';
import '../record/record_view.dart';
import 'dart:async';

import '../transcribe/transcribe_view.dart';

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
    required this.tokenid,
    required this.controller,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _transcriptionsFuture;
  final Connectivity _connectivity = Connectivity();
  late final Stream<ConnectivityResult> _connectivityStream;
  // final dndPlugin = DoNotDisturbPlugin();
  bool isListening = false;
  List<Map<String, dynamic>> _currentTranscriptions = [];

  late ManualSttController _controller;
  ManualSttState _currentState = ManualSttState.stopped;
  String _finalRecognizedText = '';
  // late ManualSttController _controller;

  ManualSttState currentState = ManualSttState.stopped;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch fresh data every time the dependencies change,
    _transcriptionsFuture = ApiService().fetchTranscriptions(widget.tokenid);
    _refreshData();
  }

  @override
  void initState() {
    super.initState();
    print("App initialized");
    // _transcriptionsFuture = ApiService().fetchTranscriptions(widget.tokenid);
    // Provider.of<AppState>(context, listen: false).monitorInternet(context);
    _connectivityStream =
        _connectivity.onConnectivityChanged.cast<ConnectivityResult>();
    _monitorInternet();
    WidgetsBinding.instance.addObserver(this);
    _controller = ManualSttController(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.settings.arguments == true) {
        _showRefreshAlertDialog();
        _refreshData(); // Refresh data when returning from another page
      }
    });

    Future.delayed(Duration.zero, () {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.showRecordingPage) {
        print("First-time launch: Navigating to RecordView");
      }
    });

  }
  //////////////////////////////////////
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("App resumed. Checking DND permission again.");
      // _checkDndPermission();
    } else if (state == AppLifecycleState.paused) {
      print("App moved to background.");
      // Stop recording if needed
      if (isListening) {
        widget.controller.stopStt();
      }
    }
  }

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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
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
          _transcriptionsFuture = fetchTranscriptions(); // Refresh the data
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
      // Handle the error
      print('Error: $e');
      _showErrorDialog(context, '$e');
    }
  }

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
                Navigator.of(context).pop(); // Close the dialog
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
        throw Exception(
            'Failed to load transcriptions. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching transcriptions: $e");
      throw Exception('Failed to load transcriptions');
    }
  }

  Future<void> _refreshData() async {
    try {
      final newTranscriptions =
          await ApiService().fetchTranscriptions(widget.tokenid);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.75;

    final appState = Provider.of<AppState>(context);

    return WillPopScope(
      onWillPop: () async {
        // Exit the app directly
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
              SvgPicture.asset(
                'assets1/Oscar Logo with Text.svg',
                width: imageSize,
                height: imageSize * 0.15,
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
                      MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                              profileName: widget.profileName,
                              profilePicUrl: widget.profilePicUrl)));
                },
              )
            ],
          ),
        ),
        body: RefreshIndicator(
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
                      AlwaysScrollableScrollPhysics(), // Ensures scroll even when empty
                  child: Container(
                    height:
                        mq.height - kToolbarHeight, // Full height minus AppBar
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Center the content vertically
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Center the content horizontally
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

                          // The image
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
                          padding: EdgeInsets.symmetric(
                              horizontal: mq.width *
                                  0.05), // Added padding on left and right
                          itemCount: transcriptions.length,
                          itemBuilder: (context, index) {
                            final transcription =
                                transcriptions.reversed.toList()[index];
                            final formattedDate =
                                _formatDate(transcription['createdAt']);
                            // Determine maxLines based on the text length
                            int maxLines;
                            if (transcription.length <= 50) {
                              maxLines = 1; // Short text
                            } else if (transcription.length <= 150) {
                              maxLines = 2; // Medium text
                            } else {
                              maxLines = 5; // Long text
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
                                            CrossAxisAlignment.start,
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
                                                            'userTextInput'],
                                                    title:
                                                        transcription['title'],
                                                    tokenid: widget.tokenid,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                                //height: 200.0,
                                                child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    transcription['title'] ??
                                                        'Untitled', // Display the title or fallback text
                                                    style: GoogleFonts.karla(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    transcription[
                                                        'transcribedText'],
                                                    maxLines:
                                                        maxLines, // Dynamic number of lines
                                                    overflow: TextOverflow
                                                        .ellipsis, // Truncate extra text
                                                    style: GoogleFonts.karla(
                                                        fontSize: 14.0,
                                                        fontWeight:
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
                                                                AppColors.Text3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        floatingActionButton: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              // width: mq.width*1/7,
              height: 64,
              decoration: BoxDecoration(
                // color: AppColors.flotingButton,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  height: 64,
                  // width: mq.width*1/10,
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
                          if (currentState == ManualSttState.stopped) {
                            widget.controller.startStt();
                            print("Recording started on home page");
                          }
                          appState.navigateToRecordingPage(widget.controller); // Correctly call the method
                          // final appState = Provider.of<AppState>(context, listen: false);
                          // try {
                          //   // Check microphone permission only when needed
                          //   var status = await Permission.microphone.request();
                          //   if (status.isGranted) {
                          //     print("Microphone permission granted. Starting recording...");
                          //     await _checkDndPermission();
                          //     await _enableDndMode();
                          //     appState.navigateToRecordingPage();
                          //     await appState.refreshData();
                          //   } else {
                          //     print("Microphone permission denied. Cannot start recording.");
                          //   }
                          // } catch (e) {
                          //   print('Error occurred: $e');
                          // }

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
  }
}
