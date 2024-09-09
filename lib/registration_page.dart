import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'terms.dart';  // Import the terms page

class RegisterContratantePage extends StatefulWidget {
  @override
  _RegisterContratantePageState createState() => _RegisterContratantePageState();
}

class _RegisterContratantePageState extends State<RegisterContratantePage> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _role = 'contratante';

  String _cep = '';
  String _rua = '';
  String _numero = '';
  String _state = '';
  String _city = '';
  String _country = 'Brasil';

  bool _acceptedTerms = false;  // Track if the user accepted the terms

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Você deve aceitar os Termos de Uso para prosseguir.'),
        ));
        return;
      }

      try {
        // Create a new user with email and password
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Get the user's UID from FirebaseAuth and add it to the Firestore document
        String uid = userCredential.user!.uid;

        // Store the user data in Firestore, including the UID
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fullName': _fullName,
          'email': _email,
          'role': _role,
          'cep': _cep,
          'rua': _rua,
          'numero': _numero,
          'state': _state,
          'city': _city,
          'country': _country,
          'uid': uid, // Add UID to the user document
        });

        // Navigate to the home page or wherever you want after registration
        Navigator.pushReplacementNamed(context, '/');
      } on FirebaseAuthException catch (e) {
        print('Failed with error code: ${e.code}');
        print(e.message);
      }
    }
  }


  Future<void> _fetchAddressFromCEP(String cep) async {
    final String url = 'https://viacep.com.br/ws/$cep/json/';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('erro')) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CEP não encontrado')));
        } else {
          setState(() {
            _state = data['uf'] ?? '';
            _city = data['localidade'] ?? '';
            _rua = data['logradouro'] ?? '';  // Autofill the street
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar CEP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao conectar com API de CEP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.yellow[700],
          title: Text('Cadastro de Usuario'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    SizedBox(height: 60),
    Center(
    child: Text(
    'PJ',
    style: TextStyle(
    fontSize: 50,
    fontWeight: FontWeight.bold,
    color: Colors.yellow[700],
    ),
    ),
    ),
    SizedBox(height: 20),
    Center(
    child: Text(
    'Insira suas informações para ingressar no APP!',
    style: TextStyle(
    fontSize: 16,
    color: Colors.grey[700],
    ),
    ),
    ),
    SizedBox(height: 40),
    Form(
    key: _formKey,
    child: Column(
    children: [
    TextFormField(
    decoration: InputDecoration(
    labelText: 'Nome Completo',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    onChanged: (value) {
    setState(() {
    _fullName = value;
    });
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'E-mail',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    onChanged: (value) {
    setState(() {
    _email = value;
    });
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'Senha',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    obscureText: true,
    onChanged: (value) {
    setState(() {
    _password = value;
    });
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'Confirmar Senha',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    obscureText: true,
    onChanged: (value) {
    setState(() {
    _confirmPassword = value;
    });
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'CEP',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    keyboardType: TextInputType.number,
    onChanged: (value) {
    setState(() {
    _cep = value;
    });
    if (value.length == 8) {
    _fetchAddressFromCEP(value);
    }
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'Rua',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    controller: TextEditingController(text: _rua),
    readOnly: true,
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'Número',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    onChanged: (value) {
    setState(() {
    _numero = value;
    });
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'Cidade',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    controller: TextEditingController(text: _city),
    readOnly: true,
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'Estado',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
    controller: TextEditingController(text: _state),
    readOnly: true,
    ),
    SizedBox(height: 20),
    TextFormField(
    decoration: InputDecoration(
    labelText: 'País',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    ),
      controller: TextEditingController(text: _country),
      readOnly: true,
    ),
      SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: _acceptedTerms,
            onChanged: (bool? value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TermsPage()),
                );
              },
              child: Text.rich(
                TextSpan(
                  text: 'Eu li e aceito os ',
                  children: [
                    TextSpan(
                      text: 'Termos de Uso',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 40),
      ElevatedButton(
        onPressed: _register,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: Colors.yellow[700],
        ),
        child: Text(
          'Confirme seus dados',
          style: TextStyle(fontSize: 16),
        ),
      ),
    ],
    ),
    ),
    ],
    ),
        ),
        ),
    );
  }
}

