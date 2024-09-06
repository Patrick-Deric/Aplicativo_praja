import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ServiceDetailsPage extends StatefulWidget {
  final String docId; // Required parameter for document ID
  final double distance; // Required parameter for distance

  ServiceDetailsPage({required this.docId, required this.distance});

  @override
  _ServiceDetailsPageState createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  Map<String, dynamic>? _serviceData;
  bool _isLoading = true;
  String _whatsappNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
    _checkAndDeleteExpiredRequests(); // Remove expired requests
  }

  // Fetch the service details from Firestore
  Future<void> _fetchServiceDetails() async {
    try {
      DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.docId)
          .get();

      if (serviceSnapshot.exists) {
        setState(() {
          _serviceData = serviceSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching service details: $e');
    }
  }

  // Check and remove service requests older than 24 hours
  Future<void> _checkAndDeleteExpiredRequests() async {
    final now = DateTime.now();
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('service_requests')
        .get();

    for (var doc in snapshot.docs) {
      Timestamp timestamp = doc['timestamp'];
      DateTime requestTime = timestamp.toDate();
      if (now.difference(requestTime).inHours >= 24) {
        await FirebaseFirestore.instance.collection('service_requests').doc(doc.id).delete();
      }
    }
  }

// Send the WhatsApp number to the service provider
  Future<void> _sendWhatsappNumber() async {
    try {
      // Debug print to log the data being sent
      print({
        'contratanteId': FirebaseAuth.instance.currentUser!.uid,
        'contratanteWhatsapp': _whatsappNumber,
        'serviceId': widget.docId,
        'providerId': _serviceData!['providerId'],
        'timestamp': Timestamp.now(),
        'status': 'pending', // Initially pending status
      });

      await FirebaseFirestore.instance.collection('service_requests').add({
        'contratanteId': FirebaseAuth.instance.currentUser!.uid,
        'contratanteWhatsapp': _whatsappNumber,
        'serviceId': widget.docId,
        'providerId': _serviceData!['providerId'],
        'timestamp': Timestamp.now(),
        'status': 'pending', // Initially pending status
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Número do WhatsApp enviado com sucesso!')),
      );
    } catch (e) {
      print('Error sending WhatsApp number: $e');
    }
  }


  // Format the available dates
  String _formatAvailableDates(List<dynamic>? availableDates) {
    if (availableDates == null || availableDates.isEmpty) return 'Não disponível';
    DateTime startDate = DateTime.parse(availableDates.first);
    DateTime endDate = DateTime.parse(availableDates.last);
    return '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Detalhes do Serviço')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Serviço'),
        backgroundColor: Colors.yellow[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                _serviceData!['serviceType'] ?? 'Tipo de serviço não disponível',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Pretensão Salarial: ${_serviceData!['salaryRange'] ?? 'Não disponível'}',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              Text(
                'Datas Disponíveis: ${_formatAvailableDates(_serviceData!['availableDates'])}',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              Text(
                'Distância: ${widget.distance.toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              Text(
                'Informe seu WhatsApp:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Seu número de WhatsApp',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _whatsappNumber = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _whatsappNumber.isEmpty ? null : _sendWhatsappNumber,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.yellow[700],
                ),
                child: Text(
                  'Enviar Número de WhatsApp',
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



