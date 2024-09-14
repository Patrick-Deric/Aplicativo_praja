import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      body: SafeArea(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            // Background image covering the bottom half of the screen
            image: DecorationImage(
              image: AssetImage('assets/agora.png'), // Replace with your correct image path
              fit: BoxFit.cover, // Ensures the image covers the entire container
              alignment: Alignment.bottomCenter, // Align to the bottom
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40), // Space from top

                // Fade-in title
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(seconds: 2),
                  builder: (context, double opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align subtitle to the left
                          children: [
                            Center(
                              child: Text(
                                'PraJá',
                                style: GoogleFonts.getFont(
                                  'Montserrat',
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow[700],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Prestação e agendamento de serviços rápidos',
                              style: GoogleFonts.getFont(
                                'Montserrat',
                                fontSize: 18,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.left, // Align subtitle to the left
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20),

                // Fade-in image (increased size)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(seconds: 2),
                  builder: (context, double opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Center(
                        child: Image.asset(
                          'assets/workerlogo.png', // Replace with the correct path for the worker image
                          height: screenHeight * 0.3, // Increased size for responsiveness
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.05), // Reduced margin between image and buttons

                // Fade-in Buttons with improved design
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: -50, end: 0),
                  duration: Duration(seconds: 1),
                  builder: (context, double offset, child) {
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login'); // Navigate to login
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: Size(double.infinity, 50), // Full-width buttons
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register'); // Navigate to contratante registration
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: Size(double.infinity, 50), // Full-width buttons
                              ),
                              child: Text(
                                'Registrar',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.1), // Adjust space between buttons and the bottom

                // Registrar como Prestador as a string at the bottom
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register_prestador'); // Navigate to prestador registration
                    },
                    child: Text(
                      'Registrar como Prestador de Serviço',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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


