import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class PostService extends StatefulWidget {
  @override
  _PostServiceState createState() => _PostServiceState();
}

class _PostServiceState extends State<PostService> {
  final _formKey = GlobalKey<FormState>();
  String _serviceType = '';
  String _salaryRange = '';
  List<DateTime> _availableDates = [];
  String _cep = '';
  String _fullName = '';
  String _userRole = '';
  String _selectedLocation = ''; // CEP or Current Location
  bool _useCurrentLocation = false;
  Position? _currentPosition;

  List<String> _serviceTypes = [
    'Pintor', 'Eletricista', 'Encanador', 'Faxineira', 'Cuidadora', 'Pedreiro',
    'Marceneiro', 'Motorista', 'Jardineiro', 'Manicure', 'Costureira', 'Técnico Informática'
  ];

  List<String> _salaryRanges = [
    'R\$20 - R\$40', 'R\$40 - R\$60', 'R\$60 - R\$80',
    'R\$80 - R\$100', 'R\$100 - R\$120', 'R\$120 - R\$140',
    'R\$140 - R\$160', 'R\$160 - R\$180', 'R\$180 - R\$200', '+R\$200'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null) {
            setState(() {
              _cep = data['cep'] ?? '';
              _fullName = data['fullName'] ?? '';
              _userRole = data['role'] ?? '';
            });
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _submitService() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;

      if (_userRole == 'prestador') {
        if (user != null) {
          String finalLocation = _useCurrentLocation
              ? '${_currentPosition?.latitude},${_currentPosition?.longitude}'
              : _cep;

          await FirebaseFirestore.instance.collection('services').add({
            'serviceType': _serviceType,
            'salaryRange': _salaryRange,
            'availableDates': _availableDates.map((e) => e.toIso8601String()).toList(),
            'location': finalLocation,
            'providerId': user.uid,
            'status': 'pending', // Service status is pending upon posting
            'createdAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Serviço postado com sucesso!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Você não tem permissão para postar um serviço.')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _useCurrentLocation = true;
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  Future<void> _selectAvailabilityDates() async {
    List<DateTime> selectedDates = [];
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (result != null) {
      selectedDates.add(result.start);
      selectedDates.add(result.end);
    }
    setState(() {
      _availableDates = selectedDates;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Postar Serviço', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tipo de Serviço',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _serviceType.isNotEmpty ? _serviceType : null,
                items: _serviceTypes.map<DropdownMenuItem<String>>((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _serviceType = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o tipo de serviço';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Pretensão Salarial',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _salaryRange.isNotEmpty ? _salaryRange : null,
                items: _salaryRanges.map<DropdownMenuItem<String>>((String range) {
                  return DropdownMenuItem<String>(
                    value: range,
                    child: Text(range),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _salaryRange = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a sua pretensão salarial';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text('Dias Disponíveis'),
                subtitle: _availableDates.isNotEmpty
                    ? Text(
                  'De ${DateFormat('dd/MM/yyyy').format(_availableDates.first)} até ${DateFormat('dd/MM/yyyy').format(_availableDates.last)}',
                )
                    : Text('Nenhuma data selecionada'),
                trailing: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _selectAvailabilityDates,
                ),
              ),
              SizedBox(height: 20),
              SwitchListTile(
                title: Text('Usar localização atual'),
                value: _useCurrentLocation,
                onChanged: (bool value) async {
                  if (value) {
                    await _getCurrentLocation();
                  } else {
                    setState(() {
                      _useCurrentLocation = false;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitService,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.yellow[700],
                ),
                child: Text(
                  'Postar Serviço',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
