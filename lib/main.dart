import 'package:aplicativo_praja/service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'registration_page.dart';
import 'registration_prestador.dart';
import 'landing_page.dart';
import 'home_page.dart';
import 'home_screen_provedor.dart';
import 'admin_home_page.dart';

// Make sure you replace FirebaseOptions with your project details
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAYsLrF2m3wIBiqMwC9WBjEEBErskjSOZ4",
      authDomain: "pra-ja-24bc5.firebaseapp.com",
      projectId: "pra-ja-24bc5",
      storageBucket: "pra-ja-24bc5.appspot.com",
      messagingSenderId: "1033446868426",
      appId: "1:1033446868426:web:6d599929640187fa8ffb33",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PJ App',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle service_details route to accept parameters
        if (settings.name == '/service_details') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return ServiceDetailsPage(
                docId: args['docId'],
                distance: args['distance'],
              );
            },
          );
        }

        // Define your other routes here
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => LandingPage()); // New Landing Page
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/register_contratante':
            return MaterialPageRoute(builder: (context) => RegisterContratantePage());
          case '/register_prestador':
            return MaterialPageRoute(builder: (context) => RegisterPrestadorPage());
          case '/main':
            return MaterialPageRoute(builder: (context) => HomePage());
          case '/home_prestador':
            return MaterialPageRoute(builder: (context) => HomeScreenProvedor());
          case '/admin_home':
            return MaterialPageRoute(builder: (context) => AdminHomePage());
          default:
            return null;
        }
      },
    );
  }
}
