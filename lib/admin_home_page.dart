import 'package:aplicativo_praja/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'home_screen_provedor.dart';
import 'login_page.dart';
import 'register_user_page.dart';
import 'blank_page_1.dart';
import 'blank_page_2.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String? role;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          role = userDoc['role'];
        });
      }
    }
  }

  Future<void> _logoff() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF36666E),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logoff,
          ),
        ],
      ),
      body: role == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.6,
          children: <Widget>[
            _buildMenuButton(
              icon: Icons.home,
              color: Colors.blue,
              title: 'Home Contratante',
              subtitle: 'Contratante de serviço',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
            _buildMenuButton(
              icon: Icons.person_add,
              color: Colors.green,
              title: 'Adicionar Usuario',
              subtitle: 'Registrar novo usuario',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterContratantePage()),
                );
              },
            ),
            _buildMenuButton(
              icon: Icons.home,
              color: Colors.orange,
              title: 'Home Prestador',
              subtitle: 'Prestador de Serviços',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreenProvedor()),
                );
              },
            ),
            _buildMenuButton(
              icon: Icons.insert_drive_file,
              color: Colors.purple,
              title: 'sla',
              subtitle: 'sla',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BlankPage2()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                radius: 40,
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
