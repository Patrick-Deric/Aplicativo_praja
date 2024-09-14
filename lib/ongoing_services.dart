import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OngoingServicesPage extends StatefulWidget {
  @override
  _OngoingServicesPageState createState() => _OngoingServicesPageState();
}

class _OngoingServicesPageState extends State<OngoingServicesPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(
        child: Text('Usuário não autenticado'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Serviços em Andamento'),
        backgroundColor: Colors.yellow[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_requests')
            .where('status', isEqualTo: 'ongoing')
            .where('providerId', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var ongoingServices = snapshot.data!.docs;

          if (ongoingServices.isEmpty) {
            return Center(
              child: Text('Nenhum serviço em andamento.'),
            );
          }

          return ListView.builder(
            itemCount: ongoingServices.length,
            itemBuilder: (context, index) {
              var service = ongoingServices[index];
              return _buildOngoingServiceCard(context, service);
            },
          );
        },
      ),
    );
  }

  // Function to build a card for each ongoing service
  Widget _buildOngoingServiceCard(BuildContext context, QueryDocumentSnapshot service) {
    String requestId = service.id;

    // Handle missing 'createdAt' field with a fallback
    DateTime createdAt;
    var serviceData = service.data() as Map<String, dynamic>?;

    if (serviceData != null && serviceData.containsKey('createdAt')) {
      createdAt = serviceData['createdAt'].toDate();
    } else {
      createdAt = DateTime.now(); // Default fallback, or handle differently
    }

    String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Serviço em Andamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Solicitado em: $formattedTime'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _completeService(requestId, service.data() as Map<String, dynamic>);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Text(
                'Concluir Serviço',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to complete the service and move it to 'completed_services' collection
  Future<void> _completeService(String requestId, Map<String, dynamic> serviceData) async {
    try {
      // Add the service to the 'completed_services' collection
      await FirebaseFirestore.instance.collection('completed_services').add({
        ...serviceData,
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });

      // Remove the service from 'service_requests'
      await FirebaseFirestore.instance.collection('service_requests').doc(requestId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço concluído com sucesso!')),
      );
    } catch (e) {
      print('Error completing service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir o serviço.')),
      );
    }
  }
}


