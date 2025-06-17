// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class SecondPage extends StatefulWidget {
//   final String terms;
//   final String heading;
//   final launchmail;
//   SecondPage(this.terms, this.heading, this.launchmail);

//   @override
//   State<SecondPage> createState() => _SecondPageState();
// }

// class _SecondPageState extends State<SecondPage> {
//   @override
//   Widget build(BuildContext context) {
//     var mq = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, size: mq.width * 0.06),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         backgroundColor: Colors.white,
//         title: Text(
//           widget.heading,
//           style: GoogleFonts.spectral(fontWeight: FontWeight.w700),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top:0),
//           child: Center(
//             child: Column(
//               children: [
//                 Text(
//                   widget.terms,
//                   style: GoogleFonts.karla(fontSize: 18),
//                 ),
//                 // SizedBox(
//                 //   width: 15,
//                 // ),
//                 InkWell(
//                   onTap: widget.launchmail,
//                   child: Text(
//                     'platforms@samyarth.org',
//                     style: GoogleFonts.karla(color: Colors.blue, fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecondPage extends StatefulWidget {
  final String terms;
  final String heading;
  final VoidCallback launchmail;

  SecondPage(this.terms, this.heading, this.launchmail);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    // Regular expression to find the email address in the text
    final emailRegex = RegExp(r'platforms@samyarth.org');
    final matches = emailRegex.allMatches(widget.terms);

    List<TextSpan> spans = [];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: widget.terms.substring(start, match.start),
          style: GoogleFonts.karla(fontSize: 16, color: Color.fromRGBO(74, 74, 74, 1),height: 1.5,),
        ));
      }

      spans.add(TextSpan(
        text: match.group(0),
        style: GoogleFonts.karla(
          fontSize: 16,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()..onTap = widget.launchmail,
      ));

      start = match.end;
    }

    if (start < widget.terms.length) {
      spans.add(TextSpan(
        // text : widget.terms.substring(start).trimLeft(),
        text: widget.terms.substring(start),
        
        style: GoogleFonts.karla(fontSize: 16, color: Color.fromRGBO(74, 74, 74, 1),height: 1.8,),
      ));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: mq.width * 0.06),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        title: Text(
          widget.heading.trimLeft(),
          style: GoogleFonts.karla(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 0),
        child: RichText(
          text: TextSpan(children: spans),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}
