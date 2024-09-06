import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileContratantePage extends StatefulWidget {
  @override
  _ProfileContratantePageState createState() => _ProfileContratantePageState();
}

class _ProfileContratantePageState extends State<ProfileContratantePage> {
  User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (_user != null) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        setState(() {
          _userData = userSnapshot.data() as Map<String, dynamic>?;
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching user profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Perfil')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil do Contratante'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/avatar.jpg'), // Replace with actual profile picture
            ),
            SizedBox(height: 20),
            Text(
              _userData?['name'] ?? 'Nome não disponível',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Email: ${_userData?['email'] ?? 'Email não disponível'}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Text(
              'Telefone: ${_userData?['phone'] ?? 'Telefone não disponível'}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement edit profile functionality
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.yellow[700],
              ),
              child: Text(
                'Editar Perfil',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
