import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'terms.dart'; // Import the terms page

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

  bool _acceptedTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String _errorMessage = '';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Você deve aceitar os Termos de Uso para prosseguir.'),
        ));
        return;
      }

      try {
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        String uid = userCredential.user!.uid;

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
          'uid': uid,
        });

        Navigator.pushReplacementNamed(context, '/');
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = 'Erro: ${e.message}';
        });
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
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('CEP não encontrado')));
        } else {
          setState(() {
            _state = data['uf'] ?? '';
            _city = data['localidade'] ?? '';
            _rua = data['logradouro'] ?? '';
          });
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao buscar CEP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar com API de CEP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Cadastro de Usuário'),
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
              SizedBox(height: 20),
              Center(
                child: Text(
                  'PraJá',
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

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Nome Completo',
                      onChanged: (value) => _fullName = value,
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      label: 'E-mail',
                      onChanged: (value) => _email = value,
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    SizedBox(height: 20),
                    _buildPasswordField(
                      label: 'Senha',
                      isVisible: _isPasswordVisible,
                      onChanged: (value) => _password = value,
                      onToggleVisibility: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    SizedBox(height: 20),
                    _buildPasswordField(
                      label: 'Confirmar Senha',
                      isVisible: _isConfirmPasswordVisible,
                      onChanged: (value) => _confirmPassword = value,
                      onToggleVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        } else if (value != _password) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      label: 'CEP',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _cep = value;
                        });
                        if (value.length == 8) {
                          _fetchAddressFromCEP(value);
                        }
                      },
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    SizedBox(height: 20),
                    _buildReadOnlyField(label: 'Rua', value: _rua),
                    SizedBox(height: 20),
                    _buildTextField(
                      label: 'Número',
                      onChanged: (value) => _numero = value,
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    SizedBox(height: 20),
                    _buildReadOnlyField(label: 'Cidade', value: _city),
                    SizedBox(height: 20),
                    _buildReadOnlyField(label: 'Estado', value: _state),
                    SizedBox(height: 20),
                    _buildReadOnlyField(label: 'País', value: _country),
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
                                MaterialPageRoute(
                                    builder: (context) => TermsPage()),
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
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                        backgroundColor: Colors.yellow[700],
                      ),
                      child: Text(
                        'Confirme seus dados',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _buildTextField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool isVisible,
    required ValueChanged<String> onChanged,
    required VoidCallback onToggleVisibility,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleVisibility,
        ),
      ),
      obscureText: !isVisible,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      controller: TextEditingController(text: value),
      readOnly: true,
    );
  }
}


