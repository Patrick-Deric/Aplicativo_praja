import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom.dart'; // Assuming you have a chatroom page

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

  // Function to accept a service request with confirmation dialog
  Future<void> _acceptServiceRequest(String requestId, String serviceId, String chatRoomId) async {
    bool accept = await _showConfirmationDialog(
      context,
      "Aceitar Serviço",
      "Você deseja aceitar este serviço?",
    );

    if (accept) {
      try {
        await FirebaseFirestore.instance.collection('service_requests').doc(requestId).update({
          'status': 'ongoing',
        });

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
  }

  // Confirmation dialog
  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Sim'),
          ),
        ],
      ),
    );
  }

  // Function to navigate to the chatroom (generating the chatRoomId dynamically)
  void _navigateToChatRoom(String contratanteId, String providerId, String serviceId) {
    // Generate the chatRoomId dynamically
    String chatRoomId = '${contratanteId}_$providerId';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          chatRoomId: chatRoomId,
          providerId: providerId,
          serviceId: serviceId,
        ),
      ),
    );
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

  // Function to build a request card widget with contratante's name and chat button
  Widget _buildRequestCard(BuildContext context, QueryDocumentSnapshot request) {
    String requestId = request.id;
    Timestamp timestamp = request['timestamp'];
    DateTime requestTime = timestamp.toDate();
    String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(requestTime);

    String contratanteId = request['contratanteId'];
    String providerId = FirebaseAuth.instance.currentUser!.uid;
    String serviceId = request['serviceId'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(contratanteId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(
            title: Text('Carregando...'),
          );
        }

        var contratanteData = snapshot.data!.data() as Map<String, dynamic>;
        String contratanteName = contratanteData['fullName'] ?? 'Nome não disponível';

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
                Text('Solicitado em: $formattedTime'),
                Text('Solicitado por: $contratanteName'),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _acceptServiceRequest(requestId, serviceId, '${contratanteId}_$providerId');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          'Aceitar Serviço',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToChatRoom(contratanteId, providerId, serviceId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          'Ir para o Chat',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

