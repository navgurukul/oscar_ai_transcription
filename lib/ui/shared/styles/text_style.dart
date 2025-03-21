
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyles {
  static TextStyle defaultTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {

    return GoogleFonts.spectral(
      textStyle: TextStyle(
        fontSize: fontSize ?? 14.0,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Colors.black,
      ),
    );
  }
}