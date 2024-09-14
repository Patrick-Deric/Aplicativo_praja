import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'rate_service.dart';  // Import the rating page

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
            .where('status', whereIn: ['ongoing', 'completed'])  // Fetch both ongoing and completed services
            .where('contratanteId', isEqualTo: userId)  // Only services for this contratante
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var ongoingServices = snapshot.data!.docs;

          if (ongoingServices.isEmpty) {
            return Center(
              child: Text('Nenhum serviço em andamento ou concluído.'),
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

  // Function to build a card for each ongoing or completed service
  Widget _buildOngoingServiceCard(BuildContext context, QueryDocumentSnapshot service) {
    String providerId = service['providerId'];
    String serviceId = service.id;
    String status = service['status'];
    Timestamp timestamp = service['timestamp'];
    DateTime requestTime = timestamp.toDate();
    String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(requestTime);

    // Fetch provider details (name and jobRole)
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('prestadores_de_servico').doc(providerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var providerData = snapshot.data!.data() as Map<String, dynamic>?;
        String providerName = providerData?['fullName'] ?? 'Nome não disponível';
        String jobRole = providerData?['jobRole'] ?? 'Profissão não disponível';

        return Card(
          margin: EdgeInsets.all(10),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'completed' ? 'Serviço Concluído' : 'Serviço em Andamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Prestador: $providerName'), // Show provider's name
                Text('Profissão: $jobRole'), // Show provider's job role
                SizedBox(height: 10),
                Text('Solicitado em: $formattedTime'),
                SizedBox(height: 10),
                if (status == 'completed')  // Show rating button if service is completed
                  ElevatedButton(
                    onPressed: () {
                      _rateService(serviceId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: Text(
                      'Avaliar Serviço',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to navigate to the rate service page
  void _rateService(String serviceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateServicePage(serviceId: serviceId),  // Only pass serviceId
      ),
    );
  }
}

