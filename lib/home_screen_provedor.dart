import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'chatlist.dart';
import 'login_page.dart'; // Import your login page


class HomeScreenProvedor extends StatefulWidget {
  @override
  _HomeScreenProvedorState createState() => _HomeScreenProvedorState();
}

class _HomeScreenProvedorState extends State<HomeScreenProvedor> {
  User? _currentUser;
  String _userName = '';
  Position? _currentPosition;

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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userName = userDoc['fullName'] ?? '';
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Log out the user
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage())); // Redirect to login page
  }

  Widget _buildCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.yellow[700]),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo'),
        backgroundColor: Colors.yellow[700],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Call the logout function
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting with user's name
            Text(
              'Olá, $_userName!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[700],
              ),
            ),
            SizedBox(height: 20),
            // Cards for navigation
            _buildCard('Perfil', Icons.person, () {
              Navigator.pushNamed(context, '/profile'); // Navigate to profile page
            }),
            SizedBox(height: 10),
            _buildCard('Serviços requisitados', Icons.room_service, () {
              Navigator.pushNamed(context, '/service_requests'); // Navigate to ongoing services page
            }),
            SizedBox(height: 10),
            _buildCard('Serviços em andamento', Icons.work, () {
              Navigator.pushNamed(context, '/ongoing_services'); // Navigate to ongoing services page
            }),
            SizedBox(height: 10),
            _buildCard('Alertas e Solicitações', Icons.notifications, () {
              Navigator.pushNamed(context, '/service_requests'); // Navigate to alerts and requests page
            }),
            SizedBox(height: 10),
            _buildCard('Lançar Serviço', Icons.post_add, () {
              Navigator.pushNamed(context, '/post_service'); // Navigate to current page for posting services
            }),
            SizedBox(height: 10),
            // New Chats Card
            _buildCard('Minhas Conversas', Icons.chat, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatListPage()), // Navigate to chat list page
              );
            }),
          ],
        ),
      ),
    );
  }
}

