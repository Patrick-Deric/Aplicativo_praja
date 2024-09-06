import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OngoingServicesContratantePage extends StatefulWidget {
  @override
  _OngoingServicesContratantePageState createState() => _OngoingServicesContratantePageState();
}

class _OngoingServicesContratantePageState extends State<OngoingServicesContratantePage> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Serviços em Andamento'),
        backgroundColor: Colors.yellow[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_requests')
            .where('status', isEqualTo: 'ongoing')  // Ongoing services
            .where('contratanteId', isEqualTo: userId)  // Only services for this contratante
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
    String providerId = service['providerId'];
    Timestamp timestamp = service['timestamp'];
    DateTime requestTime = timestamp.toDate();
    String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(requestTime);

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
            Text('Prestador: $providerId'), // Replace with actual provider name
            SizedBox(height: 10),
            Text('Solicitado em: $formattedTime'),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

