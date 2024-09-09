import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceRequestsPage extends StatefulWidget {
  @override
  _ServiceRequestsPageState createState() => _ServiceRequestsPageState();
}

class _ServiceRequestsPageState extends State<ServiceRequestsPage> {
  @override
  void initState() {
    super.initState();
    _checkAndDeleteExpiredRequests(); // Remove expired requests when the page loads
  }

  // Function to check and remove service requests older than 24 hours
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

  // Function to accept a service request and update the service status
  Future<void> _acceptServiceRequest(String requestId, String serviceId) async {
    try {
      // Update the status to 'ongoing' in service_requests
      await FirebaseFirestore.instance.collection('service_requests').doc(requestId).update({
        'status': 'ongoing',
      });

      // Update the service in the services collection to mark it as 'ongoing'
      await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
        'status': 'ongoing',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço aceito e agora está em andamento!')),
      );
    } catch (e) {
      print('Error accepting service: $e');
    }
  }

  // Function to mark a service as completed by the prestador
  Future<void> _completeServiceRequest(String requestId, String serviceId) async {
    try {
      // Update the status to 'completed' in service_requests
      await FirebaseFirestore.instance.collection('service_requests').doc(requestId).update({
        'status': 'completed',
      });

      // Update the service in the services collection to mark it as 'completed'
      await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
        'status': 'completed',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço finalizado com sucesso!')),
      );
    } catch (e) {
      print('Error completing service: $e');
    }
  }

  // Function to request a service and move it to service_requests collection
  Future<void> _requestService(String serviceId, String providerId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado!')),
      );
      return;
    }

    try {
      // Create a new document in the service_requests collection
      await FirebaseFirestore.instance.collection('service_requests').add({
        'serviceId': serviceId,
        'providerId': providerId,
        'contratanteId': currentUser.uid,
        'status': 'pending', // Service is pending until accepted by the provider
        'timestamp': Timestamp.now(),
        'contratanteWhatsapp': currentUser.phoneNumber ?? 'N/A',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço solicitado com sucesso!')),
      );
    } catch (e) {
      print('Error requesting service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao solicitar o serviço.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitações de Serviço'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.yellow[100],
            child: Text(
              'A requisição de serviço será apagada se o prestador não aceitar o serviço em 24h.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('service_requests')
                  .where('status', isEqualTo: 'pending')
                  .where('providerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var requests = snapshot.data!.docs;

                if (requests.isEmpty) {
                  return Center(
                    child: Text('Nenhuma solicitação de serviço no momento.'),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var request = requests[index];
                    return _buildRequestCard(context, request);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to build a request card widget
  Widget _buildRequestCard(BuildContext context, QueryDocumentSnapshot request) {
    String contratanteWhatsapp = request['contratanteWhatsapp'];
    String requestId = request.id;
    Timestamp timestamp = request['timestamp'];
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
              'Solicitação de Serviço',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('WhatsApp: $contratanteWhatsapp'),
            SizedBox(height: 10),
            Text('Solicitado em: $formattedTime'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _acceptServiceRequest(requestId, request['serviceId']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                padding: EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Text(
                'Realizar Serviço',
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
