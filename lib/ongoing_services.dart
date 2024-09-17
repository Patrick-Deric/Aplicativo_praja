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
  final TextEditingController _cancelController = TextEditingController(); // Controller for the 'cancelar' text field

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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.yellow[100],
            child: Text(
              'Aqui estão os serviços que estão em andamento. Certifique-se de finalizá-los ao concluir.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
          ),
        ],
      ),
    );
  }

  // Function to build a card for each ongoing service
  Widget _buildOngoingServiceCard(BuildContext context, QueryDocumentSnapshot service) {
    String requestId = service.id;
    var serviceData = service.data() as Map<String, dynamic>?;
    String serviceId = serviceData?['serviceId'] ?? '';
    String contratanteId = serviceData?['contratanteId'] ?? '';

    DateTime createdAt = serviceData != null && serviceData.containsKey('createdAt')
        ? serviceData['createdAt'].toDate()
        : DateTime.now();

    String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

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
                  'Serviço em Andamento',
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
                          _completeService(requestId, serviceData!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          'Concluir Serviço',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _showCancelWarning(context, requestId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          'Excluir Serviço',
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

  // Function to show cancel warning dialog
  void _showCancelWarning(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Cancelamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Para cancelar o serviço, digite "cancelar" abaixo:'),
              SizedBox(height: 10),
              TextField(
                controller: _cancelController,
                decoration: InputDecoration(
                  labelText: 'Digite "cancelar"',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_cancelController.text.trim().toLowerCase() == 'cancelar') {
                  _cancelService(requestId);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Digite "cancelar" corretamente.')),
                  );
                }
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Function to cancel the service
  Future<void> _cancelService(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('service_requests').doc(requestId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço cancelado com sucesso!')),
      );
    } catch (e) {
      print('Error canceling service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar o serviço.')),
      );
    }
  }

  // Function to complete the service and move it to 'completed_services' collection
  Future<void> _completeService(String requestId, Map<String, dynamic> serviceData) async {
    try {
      await FirebaseFirestore.instance.collection('completed_services').add({
        ...serviceData,
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'needsRating': true, // Add this field to indicate the service requires a rating
      });

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

