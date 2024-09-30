import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

// Toggle Crashlytics collection based on build mode
  if (kDebugMode) {
    // Disable Crashlytics in debug mode
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    print('Crashlytics collection disabled in Debug mode');
  } else {
    // Enable Crashlytics in release mode
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    print('Crashlytics collection enabled in Release mode');
  }

  // Set up global error handling
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(const MyApp());
}