import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePrestador extends StatefulWidget {
  @override
  _ProfilePrestadorState createState() => _ProfilePrestadorState();
}

class _ProfilePrestadorState extends State<ProfilePrestador> {
  final _auth = FirebaseAuth.instance;
  User? _user;
  File? _image;
  String? _imageUrl;

  String _fullName = '';
  String _email = '';
  String _cpf = '';
  String _cep = '';
  String _rua = '';
  String _numero = '';
  String _jobRole = '';
  double _rating = 0.0;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('prestadores_de_servico')
          .doc(_user!.uid)
          .get();

      setState(() {
        _fullName = doc['fullName'];
        _email = doc['email'];
        _cpf = doc['cpf'];
        _cep = doc['cep'];
        _rua = doc['rua'];
        _numero = doc['numero'];
        _jobRole = doc['jobRole'];
        _rating = doc['rating'] ?? 0.0;
        _imageUrl = doc['profilePictureUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    print("Image picker triggered");
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      print("Image selected: ${pickedFile.path}");
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    } else {
      print("No image selected");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nenhuma imagem selecionada')));
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null && _user != null) {
      try {
        print("Uploading image...");
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${_user!.uid}.jpg');

        await storageRef.putFile(_image!);
        print("Image uploaded successfully");

        String imageUrl = await storageRef.getDownloadURL();
        print("Image URL: $imageUrl");

        setState(() {
          _imageUrl = imageUrl;
        });

        await FirebaseFirestore.instance
            .collection('prestadores_de_servico')
            .doc(_user!.uid)
            .update({'profilePictureUrl': imageUrl});

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Imagem enviada com sucesso!')));
      } catch (e) {
        print("Error uploading image: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao enviar a imagem')));
      }
    } else {
      print("No image selected or user is null");
    }
  }

  Future<void> _saveProfile() async {
    print("Saving profile...");
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('prestadores_de_servico')
          .doc(_user!.uid)
          .update({
        'fullName': _fullName,
        'cep': _cep,
        'rua': _rua,
        'numero': _numero,
        'jobRole': _jobRole,
      });
      print("Profile saved successfully");
      setState(() {
        _isEditing = false;
      });
    }
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String value,
    required Function(String) onChanged,
    bool isPassword = false,
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
                initialValue: value,
                onChanged: onChanged,
                obscureText: isPassword,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              )
                  : ListTile(
                title: Text(label),
                subtitle: isPassword ? Text("******") : Text(value),
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
        title: Text('Perfil do Prestador', style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.yellow, // Change as per your theme
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
                      : AssetImage('assets/placeholder.png') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // User info and edit options
            Text(
              _fullName,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 20),

            // Profile fields
            _buildProfileField(
              icon: Icons.person,
              label: 'Nome Completo',
              value: _fullName,
              onChanged: (value) => _fullName = value,
            ),
            _buildProfileField(
              icon: Icons.email,
              label: 'E-mail',
              value: _email,
              onChanged: (value) => _email = value,
            ),
            _buildProfileField(
              icon: Icons.credit_card,
              label: 'CPF',
              value: _cpf,
              onChanged: (value) => _cpf = value,
            ),
            _buildProfileField(
              icon: Icons.location_on,
              label: 'CEP',
              value: _cep,
              onChanged: (value) => _cep = value,
            ),
            _buildProfileField(
              icon: Icons.home,
              label: 'Rua',
              value: _rua,
              onChanged: (value) => _rua = value,
            ),
            _buildProfileField(
              icon: Icons.home,
              label: 'Número',
              value: _numero,
              onChanged: (value) => _numero = value,
            ),
            _buildProfileField(
              icon: Icons.work,
              label: 'Profissão',
              value: _jobRole,
              onChanged: (value) => _jobRole = value,
            ),
            _buildProfileField(
              icon: Icons.lock,
              label: 'Senha',
              value: '******',
              onChanged: (value) => {}, // Password cannot be updated here
              isPassword: true,
            ),

            // Rating display
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow),
                SizedBox(width: 10),
                Text(
                  'Avaliação:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                Text(
                  _rating.toString(),
                  style: TextStyle(fontSize: 24, color: Colors.yellow),
                ),
              ],
            ),

            // Edit button
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isEditing ? _saveProfile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                padding: EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                'Salvar Alterações',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
