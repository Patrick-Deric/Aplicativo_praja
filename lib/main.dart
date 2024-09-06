import 'package:aplicativo_praja/ongoing_services_contratante.dart';
import 'package:aplicativo_praja/post_services.dart';
import 'package:aplicativo_praja/profile_contratante.dart';
import 'package:aplicativo_praja/profile_page.dart';
import 'package:aplicativo_praja/profile_prestador.dart';
import 'package:aplicativo_praja/service_requests.dart';
import 'package:aplicativo_praja/servicos.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_home_page.dart';
import 'login_page.dart';
import 'ongoing_services.dart';
import 'registration_page.dart';
import 'home_page.dart';
import 'home_screen_provedor.dart';
import 'service_details_page.dart';
import 'registration_page.dart';
import 'admin_home_page.dart';
import 'register_user_page.dart';
import 'blank_page_1.dart';
import 'blank_page_2.dart';
import 'service_requests.dart';

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
        // Handle the service_details route to accept parameters.
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
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (context) => RegisterContratantePage());
          case '/main':
            return MaterialPageRoute(builder: (context) => HomePage());
          case '/home_prestador':
            return MaterialPageRoute(builder: (context) => HomeScreenProvedor());
          case '/admin_home':
            return MaterialPageRoute(builder: (context) => AdminHomePage());
          case '/register_user':
            return MaterialPageRoute(builder: (context) => RegisterUserPage());
          case '/blank_page_1':
            return MaterialPageRoute(builder: (context) => BlankPage1());
          case '/blank_page_2':
            return MaterialPageRoute(builder: (context) => BlankPage2());
          case '/profile':
            return MaterialPageRoute(builder: (context) => ProfilePrestador());
          case '/ongoing_services':
            return MaterialPageRoute(builder: (context) => OngoingServicesPage());
          case '/service_requests':
            return MaterialPageRoute(builder: (context) => ServiceRequestsPage());
          case '/post_service':
            return MaterialPageRoute(builder: (context) => PostService());
          case '/ongoing_contratante':
            return MaterialPageRoute(builder: (context) => OngoingServicesContratantePage());
          case '/perfil_contratante':
            return MaterialPageRoute(builder: (context) => ProfileContratantePage());

          default:
            return null;
        }
      },
    );
  }
}
