import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // List of Brazilian states
  final List<String> _brazilianStates = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
  ];

  // List of job roles
  final List<String> _jobRoles = [
    'Encanador', 'Pintor', 'Faxineira', 'Cozinheira', 'Confeiteira', 'Pedreiro',
    'Eletricista', 'Marceneiro', 'Jardineiro', 'Baba', 'Garçom', 'Vigilante',
    'Motorista', 'Mecânico', 'Soldador', 'Montador de Móveis', 'Carpinteiro',
    'Cabeleireiro', 'Manicure', 'Maquiador', 'Costureira', 'Lavadeira',
    'Passadeira', 'Serralheiro', 'Técnico em Informática', 'Enfermeira',
    'Professor Particular', 'Instrutor de Autoescola', 'Tatuador'
  ];

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_password != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('As senhas não coincidem')),
        );
        return;
      }

      try {
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _state.isNotEmpty ? _state : null,
                      items: _brazilianStates.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _state = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione seu estado';
                        }
                        return null;
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
                      onChanged: (value) {
                        setState(() {
                          _city = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua cidade';
                        }
                        return null;
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
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu CEP';
                        }
                        return null;
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
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Profissão',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _jobRole.isNotEmpty ? _jobRole : null,
                      items: _jobRoles.map<DropdownMenuItem<String>>((String jobRole) {
                        return DropdownMenuItem<String>(
                          value: jobRole,
                          child: Text(jobRole),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _jobRole = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione sua profissão';
                        }
                        return null;
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma senha';
                        }
                        return null;
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, confirme sua senha';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 40),
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




