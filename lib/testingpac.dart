// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// // void main() {
// //   runApp(
// //     ChangeNotifierProvider(
// //       create: (_) => AppState(),
// //       child: MyApp(),
// //     ),
// //   );
// // }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: HomeScreen(),
//     );
//   }
// }
//
// class AppState with ChangeNotifier {
//   bool _showRectangle = true;
//   bool _showCircle = false;
//   bool _showSquares = false;
//
//   bool get showRectangle => _showRectangle;
//   bool get showCircle => _showCircle;
//   bool get showSquares => _showSquares;
//
//   void hideRectangle() {
//     _showRectangle = false;
//     _showCircle = true;
//     notifyListeners();
//   }
//
//   void hideCircle() {
//     _showCircle = false;
//     _showSquares = true;
//     notifyListeners();
//   }
//
//   void hideSquares() {
//     _showSquares = false;
//     notifyListeners();
//   }
// }
//
// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<AppState>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Flutter App'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (appState.showRectangle)
//               Column(
//                 children: [
//                   Container(
//                     width: 200,
//                     height: 100,
//                     color: Colors.red,
//                     child: TextField(
//                       decoration: InputDecoration(
//                         hintText: 'Write something...',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.all(10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       appState.hideRectangle();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey,
//                     ),
//                     child: Text('Hide Rectangle'),
//                   ),
//                 ],
//               ),
//             if (appState.showCircle)
//               Column(
//                 children: [
//                   Container(
//                     width: 100,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       appState.hideCircle();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.pink,
//                     ),
//                     child: Text('Hide Circle'),
//                   ),
//                 ],
//               ),
//             if (appState.showSquares)
//               Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 50,
//                         color: Colors.green,
//                       ),
//                       SizedBox(width: 20),
//                       Container(
//                         width: 50,
//                         height: 50,
//                         color: Colors.yellow,
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       appState.hideSquares();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                     ),
//                     child: Text('Hide Squares'),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }