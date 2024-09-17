import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatlist.dart';
import 'login_page.dart'; // Import your login page

class HomeScreenProvedor extends StatefulWidget {
  @override
  _HomeScreenProvedorState createState() => _HomeScreenProvedorState();
}

class _HomeScreenProvedorState extends State<HomeScreenProvedor> {
  User? _currentUser;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUserData();
  }

  Future<void> _getCurrentUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });

      // Fetch user's name from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userName = userDoc['fullName'] ?? '';
      });
    }
  }

  // Confirm logout with a dialog in Portuguese
  Future<void> _confirmLogout() async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Logout'),
          content: Text('Você realmente deseja sair?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel logout
              },
            ),
            TextButton(
              child: Text('Sair'),
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      _logout();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Log out the user
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    ); // Redirect to login page
  }

  // Helper function to create cards with cleaner UI
  Widget _buildCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.yellow[700]?.withOpacity(0.2),
                child: Icon(icon, size: 30, color: Colors.yellow[700]),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back arrow
        title: Text(
          'Bem-vindo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.yellow[700],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _confirmLogout, // Show logout confirmation
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting with user's name
            Text(
              'Olá, $_userName!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[700],
              ),
            ),
            SizedBox(height: 30),

            // Navigation Cards with improved UI
            _buildCard('Perfil', Icons.person, () {
              Navigator.pushNamed(context, '/profile');
            }),
            SizedBox(height: 15),
            _buildCard('Lançar Serviço', Icons.post_add, () {
              Navigator.pushNamed(context, '/post_service');
            }),
            SizedBox(height: 15),
            _buildCard('Serviços requisitados', Icons.room_service, () {
              Navigator.pushNamed(context, '/service_requests');
            }),
            SizedBox(height: 15),
            _buildCard('Serviços em andamento', Icons.work, () {
              Navigator.pushNamed(context, '/ongoing_services');
            }),
            SizedBox(height: 15),
            _buildCard('Minhas Conversas', Icons.chat, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatListPage()),
              );
            }),
          ],
        ),
      ),
    );
  }
}

