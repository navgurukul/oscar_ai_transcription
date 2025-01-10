import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';

// Below is the code of integrating open ai backend from meraki swagger

class Detailpage extends StatefulWidget {
  final String transcribedText;
  final String? unformattedText;
  final String tokenid;
  // final bool isEmptyInput;
  // final date;
  final String id1;
  final String? title;

  const Detailpage({
    Key? key,
    required this.tokenid,
    required this.transcribedText,
    required this.unformattedText,
    required this.id1,
    // required String date,
    required this.title,
    // required this.date,
    // required this.isEmptyInput,

    // required void Function() resetvalue
  }) : super(key: key);

  @override
  State<Detailpage> createState() => _DetailpageState();
}

class _DetailpageState extends State<Detailpage> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late TextEditingController _notFormattedText;
  bool _showTranscribedText = false;

  @override
  void initState() {
    super.initState();
    // _textController = TextEditingController(text: widget.transcribedText);
    // _notFormattedText = TextEditingController(text: widget.unformattedText);
  }

  void _handleBack() {
    Navigator.pop(context, 'show_popup'); // Pass a specific result
  }

  void _shareText() {
    try {
      Share.share(widget.transcribedText);
      print('Text shared successfully');
    } catch (e) {
      print('Error sharing text: $e');
    }
  }

  // Future<void> _deleteTranscription(BuildContext context) async {
  //   // widget.onDelete(); // Perform the delete operation
  //   Navigator.pop(context, 'Transcription deleted');
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('Transcription deleted')),
  //   );
  //   // Pop the current screen with the message
  // }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  @override
  void didUpdateWidget(covariant Detailpage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transcribedText != oldWidget.transcribedText) {
      // Update the text controller if the transcribed text changes
      _textController.text = widget.transcribedText;
    }
  }

  Future<void> _confirmDeleteTranscription(String id1) async {
    print('click on delete');
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user can tap outside to dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No border radius
          ),
          title: Text(
            'Confirm Delete',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this note?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            SizedBox(height: 20.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0),
              child: TextButton(
                child: Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // Text color
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.ButtonColor2,
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0),
              child: TextButton(
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  _deleteTranscription(id1); // Perform deletion
                },
              ),
            ),
          ],
        );
      },
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
        Navigator.of(context).pop();
        setState(() {
          // _transcriptionsFuture = _fetchTranscriptions(); // Refresh the data
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
    }
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                8.0), // Square shape with slightly rounded corners
          ),
          title: const Text(
            'Oops! an error occured',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            errorMessage,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ), // Display error message dynamically
          actions: [
            TextButton(
              onPressed: () {
                // _isDialogOpen = false; // Mark dialog as closed
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

    return Scaffold(
      backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: mq.width * 0.04),
            onPressed: _handleBack),
        title: Center(
          child: Text(
            'Detail transcription',
            style: TextStyle(
                fontSize: mq.width * 0.05, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color.fromRGBO(220, 236, 235, 1.0),
        toolbarHeight: mq.height * 0.1,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(mq.width * 0.04),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: mq.height * 0.2,
                      maxHeight: mq.height * 0.5,
                      minWidth: mq.width * 1.0,
                      maxWidth: mq.width * 1.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ButtonColor,
                      border: Border.all(color: AppColors.ButtonColor),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                // _textController.text,
                                widget.title == null ? '' : widget.title!,
                                style: GoogleFonts.roboto(
                                  fontSize: mq.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            // Text(
                            //   // _textController.text,
                            //   widget.date == null ? '' : widget.date,
                            //   style: GoogleFonts.roboto(
                            //     fontSize: mq.width * 0.05,
                            //     fontWeight: FontWeight.w600,
                            //   ),
                            //   textAlign: TextAlign.center,
                            // ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              // _textController.text,
                              widget.transcribedText == null
                                  ? 'No formatted text available'
                                  : widget.transcribedText!,
                              style: GoogleFonts.roboto(
                                fontSize: mq.width * 0.05,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showTranscribedText)
                  Container(
                    constraints: BoxConstraints(
                      minWidth: mq.width * 0.8,
                      maxWidth: mq.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.unformattedText == null
                              ? 'No original text is provided'
                              : widget.unformattedText!,
                          style: GoogleFonts.roboto(
                            fontSize: mq.width * 0.05,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showTranscribedText = !_showTranscribedText;
                      });
                    },
                    child: Text(
                      _showTranscribedText
                          ? 'Hide Original Transcripts'
                          : 'View Original Transcripts',
                      style: GoogleFonts.roboto(
                        fontSize: mq.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: mq.height * 0.09),
              ],
            ),
          ),
        ),
      ),
      bottomSheet:
          // widget.isEmptyInput
          //     ? _buildEmptyInputBottomSheet(context)
          //:
          _buildFullInputBottomSheet(context),
    );
  }

  Widget _buildFullInputBottomSheet(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return SafeArea(
      child: BottomAppBar(
        color: Color.fromRGBO(220, 236, 235, 1.0),
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.height * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                // width: mq.width*0.2,
                // height: mq.height*0.5,
                margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04),
                padding: EdgeInsets.symmetric(),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(mq.width * 0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SizedBox(width: 10,),
                    IconButton(
                      icon: Icon(Icons.copy, color: AppColors.ButtonColor2),
                      onPressed: _copyText,
                      iconSize: mq.width * 0.07,
                    ),
                    // SizedBox(width: 5,),
                    IconButton(
                      icon: Icon(Icons.share, color: AppColors.ButtonColor2),
                      onPressed: _shareText,
                      iconSize: mq.width * 0.07,
                    ),
                    // SizedBox(width: 5,),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppColors.ButtonColor2),
                      onPressed: () {
                        _confirmDeleteTranscription(widget.id1);
                        // _handleDeleteTranscription();
                        // Navigator.pop(context);
                        // _deleteTranscription(context);
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text('Transcription deleted'),
                        //   ),
                        // );
                        // _handleDeleteTranscription();
                        // Navigator.pop(context);
                        // onPressed: () {
                        //     _confirmDeleteTranscription(
                        //     widget.id1
                        //     );
                        //     // _deleteTranscription('3');
                        // };
                      },
                      iconSize: mq.width * 0.07,
                    ),
                    // SizedBox(width: 10,),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
