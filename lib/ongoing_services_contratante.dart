import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'rate_service.dart';  // Import the rating page
import 'chatlist.dart';
import 'ongoing_services_contratante.dart';
import 'profile_contratante.dart';

class OngoingServicesContratantePage extends StatefulWidget {
  @override
  _OngoingServicesContratantePageState createState() =>
      _OngoingServicesContratantePageState();
}

class _OngoingServicesContratantePageState
    extends State<OngoingServicesContratantePage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  int _selectedIndex = 1; // Set the selected index for ongoing services

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Serviços em Andamento', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_requests')
            .where('status', whereIn: ['ongoing', 'completed'])
            .where('contratanteId', isEqualTo: userId)
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Highlight the ongoing services tab
        selectedItemColor: Colors.yellow[700],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Serviços'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => HomePage()));
            // Add logic to navigate to the home page if necessary
          } else if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OngoingServicesContratantePage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListPage()));
          } else if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfileContratantePage()));
          }
        },
      ),
    );
  }

  Widget _buildOngoingServiceCard(
      BuildContext context, QueryDocumentSnapshot service) {
    String providerId = service['providerId'];
    String serviceId = service.id;
    String status = service['status'];
    Timestamp timestamp = service['timestamp'];
    DateTime requestTime = timestamp.toDate();
    String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(requestTime);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('prestadores_de_servico')
          .doc(providerId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var providerData = snapshot.data!.data() as Map<String, dynamic>?;
        String providerName = providerData?['fullName'] ?? 'Nome não disponível';

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
                Text('Prestador: $providerName'),
                SizedBox(height: 10),
                Text('Solicitado em: $formattedTime'),
                SizedBox(height: 10),
                Row(
                  children: [
                    if (status == 'completed')  // Show rating button if service is completed
                      Expanded(
                        child: ElevatedButton(
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
                      ),
                    if (status == 'ongoing')  // Show cancel button if service is ongoing
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _confirmCancelService(serviceId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          child: Text(
                            'Cancelar Serviço',
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

  Future<void> _confirmCancelService(String serviceId) async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Digite "cancelar" para confirmar o cancelamento do serviço'),
              TextField(
                controller: controller,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.toLowerCase() == 'cancelar') {
                  Navigator.of(context).pop('cancelar');
                }
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (result == 'cancelar') {
      _cancelService(serviceId);
    }
  }

  Future<void> _cancelService(String serviceId) async {
    try {
      await FirebaseFirestore.instance.collection('service_requests').doc(serviceId).update({
        'status': 'cancelled',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serviço cancelado com sucesso.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar o serviço.')),
      );
    }
  }

  void _rateService(String serviceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateServicePage(serviceId: serviceId),
      ),
    );
  }
}

