import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oscar_stt/core/constants/app_colors.dart';
import 'package:oscar_stt/ui/views/record/record_view.dart';

class EmptyScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
var mq = MediaQuery.of(context).size;
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
                  Navigator.pop(context);
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
                        // Add your microphone handling logic here
                        print("Microphone button pressed");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordView(
                              onRecordingComplete: (String recording) {
                                // Handle recording completion here
                              },
                              tokenid: '',),),);},),),),),),],),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
}}