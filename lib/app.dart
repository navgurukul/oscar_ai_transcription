// import 'package:oscar_stt/core/viewmodels/splash_viewmodel.dart';
// import 'package:oscar_stt/ui/views/auth/login_view.dart';
import 'package:flutter/material.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:oscar_stt/ui/views/CombinedScreenProvider.dart';
// import 'package:oscar_stt/ui/views/home/home_view.dart';
import 'package:provider/provider.dart';
// import 'package:testing_oscar/ui/views/CombinedScreenProvider.dart';
// import 'package:testing_oscar/ui/views/record/poc.dart';
// import 'package:testing_oscar/ui/views/record/recording2.dart';
import 'core/viewmodels/auth_viewmodel.dart';
import 'core/viewmodels/splash_viewmodel.dart';
import 'ui/views/splash/splash_view.dart';

class MyApp extends StatelessWidget {
  // final ManualSttController sttController = ManualSttController();


  MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SplashViewModel()),
          ChangeNotifierProvider(create: (_) => LoginViewModel()),
          ChangeNotifierProvider(create: (_) => AppState(tokenid: '', controller: ManualSttController(context))),
          // ChangeNotifierProvider(create: (_) => CombinedScreenProvider()), // Add this

        ],
        child: MaterialApp(
          title: 'Oscar',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          initialRoute: '/',
          home:          SplashScreen(),

        )
    );
  }
}
