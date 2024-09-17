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
  double _averageRating = 0.0;
  int _completedServices = 0;
  int _totalRatings = 0; // Total number of ratings

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserProfile();
    _loadProviderRatings();
    _loadCompletedServices();
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('prestadores_de_servico')
          .doc(_user!.uid)
          .get();

      final userData = doc.data() as Map<String, dynamic>?;

      if (userData != null) {
        setState(() {
          _fullName = userData['fullName'] ?? 'Nome não disponível';
          _email = userData['email'] ?? 'Email não disponível';
          _cpf = userData['cpf'] ?? 'CPF não disponível';
          _cep = userData['cep'] ?? 'CEP não disponível';
          _rua = userData['rua'] ?? 'Rua não disponível';
          _numero = userData['numero'] ?? 'Número não disponível';
          _imageUrl = userData['profilePictureUrl'] ?? null;
        });
      }
    }
  }

  Future<void> _loadProviderRatings() async {
    if (_user != null) {
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('providerId', isEqualTo: _user!.uid)
          .get();

      int totalRatings = ratingsSnapshot.docs.length;
      int sumRatings = ratingsSnapshot.docs.fold(
        0,
            (previousValue, doc) => previousValue + (doc['rating'] as int),
      );

      double averageRating = totalRatings > 0 ? sumRatings / totalRatings : 0.0;

      setState(() {
        _averageRating = averageRating;
        _totalRatings = totalRatings;
      });
    }
  }

  Future<void> _loadCompletedServices() async {
    if (_user != null) {
      QuerySnapshot completedServicesSnapshot = await FirebaseFirestore.instance
          .collection('completed_services')
          .where('providerId', isEqualTo: _user!.uid)
          .get();

      int completedServices = completedServicesSnapshot.docs.length;

      setState(() {
        _completedServices = completedServices;
      });
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
            .collection('prestadores_de_servico')
            .doc(_user!.uid)
            .update({'profilePictureUrl': imageUrl});
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('prestadores_de_servico')
          .doc(_user!.uid)
          .update({
        'fullName': _fullName,
        'cep': _cep,
        'rua': _rua,
        'numero': _numero,
      });
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
                title: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
        title: Text('Perfil do Prestador', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow,
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
            Text(
              _fullName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 20),

            // Row for Rating, Completed Services, and Total Ratings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow),
                    SizedBox(width: 5),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 5),
                    Text(
                      '$_completedServices Concluídos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.rate_review, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(
                      '$_totalRatings Avaliações',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
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

            // Save button
            ElevatedButton(
              onPressed: _isEditing ? _saveProfile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              ),
              child: Text('Salvar Alterações', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

