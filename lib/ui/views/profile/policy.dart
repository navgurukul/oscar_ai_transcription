
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecondPage extends StatefulWidget {
  final String terms;
  final String heading ;
  final launchmail;
  SecondPage( this.terms, this.heading,this.launchmail);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  
  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: mq.width * 0.06),
            onPressed: (){Navigator.pop(context);},
            ),
        backgroundColor: Colors.white,
        title: Text(widget.heading,style: GoogleFonts.spectral(fontWeight: FontWeight.w700),),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20,bottom: 20),
          child: Center(
            child: Column(
              children: [
                Text(
                  widget.terms,
                  style: GoogleFonts.karla(fontSize: 18),
                ),
                SizedBox(width: 15,),
                
            InkWell(
              onTap: widget.launchmail,
              child: Text('platforms@samyarth.org',style:GoogleFonts.karla(color: Colors.blue,fontSize: 18),
              ),
            ),
              ],
            ),
            
          ),
        ),
      ),
    );
  }
}
