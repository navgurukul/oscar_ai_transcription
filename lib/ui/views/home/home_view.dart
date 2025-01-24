// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:oscar_stt/core/constants/app_colors.dart';
// import 'package:oscar_stt/ui/detailpage.dart';
// import 'package:oscar_stt/ui/views/transcribe/transcribe_view.dart';
// import '../../../core/viewmodels/api_service.dart';
// import '../../shared/styles/text_style.dart';
// import '../profile/profile_view.dart';
// import '../record/record_view.dart';

// class HomePage extends StatefulWidget {
//   final String profileName;
//   final String profilePicUrl;
//   final String transcribedata;
//   final String tokenid;

//   const HomePage({
//     Key? key,
//     required this.transcribedata,
//     required this.profileName,
//     required this.profilePicUrl,
//     required this.tokenid,
//   }) : super(key: key);

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   late Future<List<Map<String, dynamic>>> _transcriptionsFuture;
//   List<Map<String, dynamic>> _currentTranscriptions = [];
//   bool _isDialogOpen = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Fetch fresh data every time the dependencies change,
//     _transcriptionsFuture = ApiService().fetchTranscriptions(widget.tokenid);
//   }

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (ModalRoute.of(context)?.settings.arguments == true) {
//         _showRefreshAlertDialog();
//         _refreshData(); // Refresh data when returning from another page
//       }
//     });
//   }

//   void dispose() {
//     super.dispose();
//   }

//   void _showRefreshAlertDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Notice'),
//           content: Text('Refresh page for new Transcription'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _refreshData() async {
//     final newTranscriptions =
//         await ApiService().fetchTranscriptions(widget.tokenid);

//     setState(() {
//       _transcriptionsFuture = Future.value(newTranscriptions);
//       _currentTranscriptions = newTranscriptions;
//     });

//     if (_currentTranscriptions.length < newTranscriptions.length) {
//       _showNewTranscriptionSnackBar();
//     }
//   }

//   void _showNewTranscriptionSnackBar() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('New transcription added'),
//         duration: Duration(seconds: 2),
//       ),
//     );
//   }

//   void _deleteTranscription(String transcriptionId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse(
//             'https://dev-oscar.merakilearn.org/api/v1/transcriptions/$transcriptionId'),
//         headers: {'Authorization': 'Bearer ${widget.tokenid}'},
//       );

//       if (response.statusCode == 200) {
//         print('deleted successfully');
//         setState(() {
//           _transcriptionsFuture = _fetchTranscriptions(); // Refresh the data
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Transcription deleted'),
//           ),
//         );
//       } else if (response.statusCode == 400) {
//         print('Bad Request');
//         _showErrorDialog(
//             context, 'Failed to delete transcription due to Bad Request');
//       } else if (response.statusCode == 404) {
//         print('Transcription not found');
//         _showErrorDialog(
//             context, 'Failed to delete due to Transcription not found');
//       } else if (response.statusCode == 500) {
//         print('Internal server error ');
//         _showErrorDialog(context,
//             'Failed to delete transcription due to Internal server error ');
//       } else {
//         _showErrorDialog(context, 'Failed to delete transcription');
//         throw Exception('Failed to delete transcription');
//       }
//     } catch (e) {
//       // Handle the error
//       print('Error: $e');
//       _showErrorDialog(context, '$e');
//     }
//   }

//   Future<List<Map<String, dynamic>>> _fetchTranscriptions() async {
//     final response = await http.get(
//       Uri.parse('https://dev-oscar.merakilearn.org/api/v1/transcriptions'),
//       headers: {'Authorization': 'Bearer ${widget.tokenid}'},
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return List<Map<String, dynamic>>.from(data['data']);
//     } else if (response.statusCode == 400) {
//       final data = jsonDecode(response.body);
//       _showErrorDialog(context, data['message']);
//       return data['message']; // Return the message from the API response
//     } else if (response.statusCode == 404) {
//       final data = jsonDecode(response.body);
//       _showErrorDialog(context, data['message']);
//       return data['message']; // Return the message from the API response
//     } else if (response.statusCode == 500) {
//       final data = jsonDecode(response.body);
//       _showErrorDialog(context, data['message']);
//       return data['message']; // Return the message from the API response
//     } else if (response.statusCode == 401) {
//       final data = jsonDecode(response.body);
//       _showErrorDialog(context, data['message']);
//       return data['message']; // Return the message from the API response
//     } else {
//       _showErrorDialog(context, 'Failed to load transcription');
//       throw Exception('Failed to load transcriptions');
//     }
//   }

//   // Function to format date
//   String _formatDate(String dateString) {
//     final date = DateTime.parse(dateString).toLocal();
//     return DateFormat('MMM dd, yyyy').format(date); // Formats to Jan 10, 2025
//   }

//   void _showErrorDialog(BuildContext context, String errorMessage) {
//     var mq = MediaQuery.of(context).size;
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dialog from closing on outside tap
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(
//                 8.0), // Square shape with slightly rounded corners
//           ),
//           title: const Text('Oops! an error occured',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               )),
//           content: Text(errorMessage,
//               style: TextStyle(
//                 fontWeight: FontWeight.w400,
//                 fontSize: mq.width * 0.04,
//                 color: Colors.black,
//               )), // Display error message dynamically
//           actions: [
//             TextButton(
//               onPressed: () {
//                 _isDialogOpen = false; // Mark dialog as closed
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text(
//                 'OK',
//                 style: TextStyle(color: Colors.white),
//               ),
//               style: ButtonStyle(
//                 backgroundColor:
//                     WidgetStateProperty.all(AppColors.ButtonColor2),
//                 padding: WidgetStateProperty.all(
//                     EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     final imageSize = screenWidth * 0.75;

//     return WillPopScope(
//       onWillPop: () async {
//         // Exit the app directly
//         await SystemNavigator.pop();
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
//         appBar: AppBar(
//           backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
//           scrolledUnderElevation: 0.0,
//           automaticallyImplyLeading: false,
//           elevation: 0,
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SvgPicture.asset(
//                 'assets1/Oscar Logo with Text.svg',
//                 width: imageSize,
//                 height: imageSize * 0.15,
//               ),
//               IconButton(
//                 icon: CircleAvatar(
//                   backgroundImage: widget.profilePicUrl != null &&
//                           widget.profilePicUrl!.isNotEmpty
//                       ? NetworkImage(widget.profilePicUrl!)
//                       : null,
//                   radius: mq.width * 0.04,
//                   backgroundColor: Colors.blue,
//                   child: widget.profilePicUrl == null ||
//                           widget.profilePicUrl!.isEmpty
//                       ? Text(
//                           widget.profileName.isNotEmpty
//                               ? widget.profileName[0].toUpperCase()
//                               : '',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: mq.width * 0.04,
//                           ),
//                         )
//                       : null,
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SettingsScreen(
//                         profileName: widget.profileName,
//                         profilePicUrl: widget.profilePicUrl,
//                       ),
//                     ),
//                   );
//                 },
//               )
//             ],
//           ),
//         ),
//         body: RefreshIndicator(
//           onRefresh: _refreshData,
//           child: FutureBuilder<List<Map<String, dynamic>>>(
//             future: _transcriptionsFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               } else if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return SingleChildScrollView(
//                   physics:
//                       AlwaysScrollableScrollPhysics(), // Ensures scroll even when empty
//                   child: Container(
//                     height:
//                         mq.height - kToolbarHeight, // Full height minus AppBar
//                     child: Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment
//                             .center, // Center the content vertically
//                         crossAxisAlignment: CrossAxisAlignment
//                             .center, // Center the content horizontally
//                         children: [
//                           Align(
//                             alignment: Alignment.topLeft,
//                             child: Padding(
//                               padding: EdgeInsets.all(mq.width * 0.05),
//                               child: Text(
//                                 "My Transcripts (0)",
//                                 style: TextStyles.defaultTextStyle(
//                                   fontSize: mq.width * 0.06,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),

//                           SizedBox(height: mq.height * 0.20),

//                           // The image
//                           Image.asset(
//                             'assets1/homeimage.png',
//                             width: 100,
//                             height: 100,
//                           ),

//                           Padding(
//                             padding: const EdgeInsets.all(10.0),
//                             child: Text(
//                               "We are excited to see what your first transcription will be",
//                               textAlign: TextAlign.center,
//                               style: TextStyles.defaultTextStyle(
//                                 fontSize: mq.width * 0.05,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),

//                           Spacer(),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               } else {
//                 List<Map<String, dynamic>> transcriptions = snapshot.data!;
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.all(mq.width * 0.05),
//                       child: Text(
//                         "My Transcripts (${transcriptions.length})",
//                         style: TextStyles.defaultTextStyle(
//                           fontSize: mq.width * 0.06,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: mq.height * 0.05),
//                     Expanded(
//                       child: Theme(
//                         data: Theme.of(context).copyWith(
//                           scrollbarTheme: ScrollbarThemeData(
//                             thumbColor:
//                                 WidgetStateProperty.all(AppColors.ButtonColor2),
//                             trackColor: WidgetStateProperty.all(Colors.white),
//                             trackVisibility: WidgetStateProperty.all(true),
//                             thumbVisibility: WidgetStateProperty.all(true),
//                             thickness: WidgetStateProperty.all(10.0),
//                             radius: Radius.circular(80.0),
//                           ),
//                         ),
//                         child: ListView.builder(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: mq.width *
//                                   0.05), // Added padding on left and right
//                           itemCount: transcriptions.length,

//                           itemBuilder: (context, index) {
//                             final transcription =
//                                 transcriptions.reversed.toList()[index];
//                             final formattedDate =
//                                 _formatDate(transcription['createdAt']);


//                                               child: Padding(
//                                                 padding: const EdgeInsets.only(
//                                                     right: 8.0, left: 8.0),
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       transcription['title'] ??
//                                                           'Untitled', // Display the title or fallback text
//                                                       style: TextStyle(
//                                                         fontSize: 18.0,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                       ),

//                                                     SizedBox(height: 8.0),
//                                                     Container(
//                                                       height: 30.0,
//                                                       child: Row(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .spaceBetween,
//                                                         children: [
//                                                           IconButton(
//                                                             icon: Icon(
//                                                               Icons.copy,
//                                                               color: Colors.black,
//                                                               size: 16.0,
//                                                             ),
//                                                             onPressed: () {
//                                                               Clipboard.setData(
//                                                                 ClipboardData(
//                                                                     text: transcription[
//                                                                         'transcribedText']),
//                                                               );
//                                                               ScaffoldMessenger
//                                                                       .of(context)
//                                                                   .showSnackBar(
//                                                                 SnackBar(
//                                                                     content: Text(
//                                                                         'Copied to clipboard')),
//                                                               );
//                                                             },
//                                                           ),
//                                                           SizedBox(width: 8.0),
//                                                           Text(
//                                                             formattedDate,
//                                                             style:
//                                                                 GoogleFonts.karla(
//                                                               fontSize: 14.0,
//                                                               fontWeight:
//                                                                   FontWeight.bold,
//                                                               color:
//                                                                   AppColors.Text3,
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     )
//                                                   ],
//                                                 ),

//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               }
//             },
//           ),
//         ),
//         floatingActionButton: Stack(
//           alignment: Alignment.center,
//           children: <Widget>[
//             Container(
//               // width: mq.width*1/7,
//               height: mq.height * 1 / 10,
//               decoration: BoxDecoration(
//                 color: AppColors.flotingButton,
//                 shape: BoxShape.circle,
//               ),
//               child: Center(
//                 child: Container(
//                   height: mq.height * 1 / 13,
//                   // width: mq.width*1/10,
//                   decoration: BoxDecoration(
//                     color: AppColors.ButtonColor2,
//                     shape: BoxShape.circle,
//                   ),

//                   child: Center(
//                     child: IconButton(
//                       icon: Icon(
//                         Icons.mic, // Microphone icon
//                         color: Colors.white, // Icon color
//                         // size: 50.0,  // Icon size
//                       ),
//                       iconSize: mq.height * 1 / 18,
//                       onPressed: () async {
//                         // Add your microphone handling logic here
//                         print("Microphone button pressed");
//                         final newTranscription = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => RecordView(
//                               onRecordingComplete: (transcribedText) {
//                                 _refreshData();
//                                 Navigator.pop(context, true);

//                                 setState(() {
//                                   _transcriptionsFuture =
//                                       _fetchTranscriptions();
//                                 });

//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => TranscribeResult(
//                                       transcribedText: transcribedText,
//                                       unformattedText: '',
//                                       title_text: '',
//                                       onDelete: () =>
//                                           _deleteTranscription(transcribedText),
//                                       tokenid: widget.tokenid,
//                                     ),
//                                   ),
//                                 );
//                               },
//                               tokenid: widget.tokenid,
//                             ),
//                           ),
//                         );
//                         if (newTranscription != null &&
//                             newTranscription == true) {
//                           _refreshData();
//                         }
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       ),
//     );
//   }
// }
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:oscar_stt/ui/detailpage.dart';
import 'package:oscar_stt/ui/views/nointernet.dart';
import 'package:oscar_stt/ui/views/transcribe/transcribe_view.dart';
import '../../../core/viewmodels/api_service.dart';
import '../../shared/styles/text_style.dart';
import '../profile/profile_view.dart';
import '../record/record_view.dart';


class HomePage extends StatefulWidget {
  final String profileName;
  final String profilePicUrl;
  final String transcribedata;
  final String tokenid;

  const HomePage({
    Key? key,
    required this.transcribedata,
    required this.profileName,
    required this.profilePicUrl,
    required this.tokenid,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _transcriptionsFuture;
  List<Map<String, dynamic>> _currentTranscriptions = [];
  bool _isDialogOpen = false;
  final Connectivity _connectivity = Connectivity();
  late final Stream<ConnectivityResult> _connectivityStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch fresh data every time the dependencies change,
    _transcriptionsFuture = ApiService().fetchTranscriptions(widget.tokenid);
  }

  @override
  void initState() {
    super.initState();
    _connectivityStream =
        _connectivity.onConnectivityChanged.cast<ConnectivityResult>();

    _monitorInternet();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.settings.arguments == true) {
        _showRefreshAlertDialog();
        _refreshData(); // Refresh data when returning from another page
      }
    });
  }

  void _monitorInternet() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // Navigate to the NoInternetScreen
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NoInternetScreen(),
        ));
      }
    });
  }

  void dispose() {
    super.dispose();
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

  Future<void> _refreshData() async {
    final newTranscriptions =
        await ApiService().fetchTranscriptions(widget.tokenid);

    setState(() {
      _transcriptionsFuture = Future.value(newTranscriptions);
      _currentTranscriptions = newTranscriptions;
    });

    if (_currentTranscriptions.length < newTranscriptions.length) {
      _showNewTranscriptionSnackBar();
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
          _transcriptionsFuture = _fetchTranscriptions(); // Refresh the data
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
      return data['message']; // Return the message from the API response
    } else if (response.statusCode == 404) {
      final data = jsonDecode(response.body);
      _showErrorDialog(context, data['message']);
      return data['message']; // Return the message from the API response
    } else if (response.statusCode == 500) {
      final data = jsonDecode(response.body);
      _showErrorDialog(context, data['message']);
      return data['message']; // Return the message from the API response
    } else if (response.statusCode == 401) {
      final data = jsonDecode(response.body);
      _showErrorDialog(context, data['message']);
      return data['message']; // Return the message from the API response
    } else {
      _showErrorDialog(context, 'Failed to load transcription');
      throw Exception('Failed to load transcriptions');
    }
  }

  // Function to format date
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('MMM dd, yyyy').format(date); // Formats to Jan 10, 2025
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
                _isDialogOpen = false; // Mark dialog as closed
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

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final imageSize = screenWidth * 0.75;

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
                        profilePicUrl: widget.profilePicUrl,
                      ),
                    ),
                  );
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
                                        // >>>>>>> Stashed changes
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
                        // Add your microphone handling logic here
                        print("Microphone button pressed");
                        final newTranscription = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordView(
                              onRecordingComplete: (transcribedText) {
                                _refreshData();
                                Navigator.pop(context, true);

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
                                      tokenid: widget.tokenid, title_text: '', isEmptyInput: false,
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
                        }
                      },
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
