import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'terms.dart';  // Import the terms page

class RegisterPrestadorPage extends StatefulWidget {
  @override
  _RegisterPrestadorPageState createState() => _RegisterPrestadorPageState();
}

class _RegisterPrestadorPageState extends State<RegisterPrestadorPage> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _gender = 'Masculino';
  String _email = '';
  String _cpf = '';
  String _city = '';
  String _state = '';
  String _country = 'Brasil';
  String _cep = '';
  String _rua = '';
  String _numero = '';
  String _jobRole = '';
  String _password = '';
  String _confirmPassword = '';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _acceptedTerms = false;  // Track if the user accepted the terms

  // List of Brazilian states
  final List<String> _brazilianStates = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
  ];

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_password != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('As senhas não coincidem')),
        );
        return;
      }

      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Você deve aceitar os Termos de Uso para prosseguir.'),
        ));
        return;
      }

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        String userId = userCredential.user!.uid;

        Map<String, dynamic> prestadorData = {
          'fullName': _fullName,
          'gender': _gender,
          'email': _email,
          'cpf': _cpf,
          'city': _city,
          'state': _state,
          'country': _country,
          'cep': _cep,
          'rua': _rua,
          'numero': _numero,
          'jobRole': _jobRole,
          'role': 'prestador',
        };

        // Store in prestadores_de_servico collection
        await FirebaseFirestore.instance
            .collection('prestadores_de_servico')
            .doc(userId)
            .set(prestadorData);

        // Also store in users collection
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'uid': userId,
          'fullName': _fullName,
          'email': _email,
          'role': 'prestador',
        });

        // Navigate to the login page after registration
        Navigator.pushReplacementNamed(context, '/');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadastro realizado com sucesso. Faça login para continuar.')),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao registrar: ${e.message}')),
        );
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
            _rua = data['logradouro'] ?? '';
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
        title: Text('Cadastro de Prestador'),
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
                  'Cadastro de Prestador',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu nome completo';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gênero',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _gender,
                      items: [
                        DropdownMenuItem(
                          child: Text('Masculino'),
                          value: 'Masculino',
                        ),
                        DropdownMenuItem(
                          child: Text('Feminino'),
                          value: 'Feminino',
                        ),
                        DropdownMenuItem(
                          child: Text('Prefiro não identificar'),
                          value: 'Prefiro não identificar',
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    // Email Field
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu e-mail';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // CPF Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'CPF',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _cpf = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu CPF';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // CEP Field
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

                    // State Field
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

                    // City Field
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

                    // Street Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Rua',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: TextEditingController(text: _rua),
                      onChanged: (value) {
                        setState(() {
                          _rua = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua rua';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Number Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Número',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _numero = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o número';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_passwordVisible,
                      onChanged: (value) {
                        setState(() {
                          _password = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma senha';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Confirm Password Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_confirmPasswordVisible,
                      onChanged: (value) {
                        setState(() {
                          _confirmPassword = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, confirme sua senha';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Terms Checkbox and Link to Terms Page
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

                    // Submit Button
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.yellow[700],
                      ),
                      child: Text(
                        'Registrar',
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
