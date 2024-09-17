import 'package:aplicativo_praja/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'chatlist.dart';
import 'ongoing_services_contratante.dart';
import 'profile_contratante.dart'; // Import your other pages as needed

class ProfileContratantePage extends StatefulWidget {
  @override
  _ProfileContratantePageState createState() => _ProfileContratantePageState();
}

class _ProfileContratantePageState extends State<ProfileContratantePage> {
  final _auth = FirebaseAuth.instance;
  User? _user;
  File? _image;
  String? _imageUrl;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  bool _isEditing = false;
  int _selectedIndex = 3; // Highlight profile icon in the nav bar

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      final userData = doc.data() as Map<String, dynamic>?;

      if (userData != null) {
        setState(() {
          _fullNameController.text = userData['fullName'] ?? 'Nome não disponível';
          _emailController.text = userData['email'] ?? 'Email não disponível';
          _cepController.text = userData['cep'] ?? 'CEP não disponível';
          _ruaController.text = userData['rua'] ?? 'Rua não disponível';
          _numeroController.text = userData['numero'] ?? 'Número não disponível';
          _imageUrl = userData.containsKey('profilePictureUrl') ? userData['profilePictureUrl'] : null;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nenhuma imagem selecionada')));
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null && _user != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${_user!.uid}.jpg');

        await storageRef.putFile(_image!);

        String imageUrl = await storageRef.getDownloadURL();

        setState(() {
          _imageUrl = imageUrl;
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'profilePictureUrl': imageUrl});

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Imagem enviada com sucesso!')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao enviar a imagem')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'fullName': _fullNameController.text,
        'cep': _cepController.text,
        'rua': _ruaController.text,
        'numero': _numeroController.text,
      });
      setState(() {
        _isEditing = false;
      });
    }
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.yellow),
            SizedBox(width: 10),
            Expanded(
              child: _isEditing
                  ? TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              )
                  : ListTile(
                title: Text(label),
                subtitle: Text(controller.text),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Perfil do Contratante', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow[700],
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageUrl != null
                      ? NetworkImage(_imageUrl!)
                      : AssetImage('assets/anon.png') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.black),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Profile fields
            _buildProfileField(
              icon: Icons.person,
              label: 'Nome Completo',
              controller: _fullNameController,
            ),
            _buildProfileField(
              icon: Icons.email,
              label: 'E-mail',
              controller: _emailController,
            ),
            _buildProfileField(
              icon: Icons.location_on,
              label: 'CEP',
              controller: _cepController,
            ),
            _buildProfileField(
              icon: Icons.home,
              label: 'Rua',
              controller: _ruaController,
            ),
            _buildProfileField(
              icon: Icons.home,
              label: 'Número',
              controller: _numeroController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,  // Highlight the profile icon
        selectedItemColor: Colors.yellow[700],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Serviços'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => HomePage()));
            // Navigate to Home
          } else if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OngoingServicesContratantePage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListPage()));
          } else if (index == 3) {
            // Stay on the profile page
          }
        },
      ),
    );
  }
}


