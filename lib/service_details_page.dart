import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chatroom.dart'; // Import ChatRoomPage

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
  String _providerName = ''; // Store the provider name

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
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
          _fetchProviderDetails(); // Fetch provider name once service details are loaded
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching service details: $e');
    }
  }

  // Fetch provider details (e.g., fullName)
  Future<void> _fetchProviderDetails() async {
    try {
      String providerId = _serviceData!['providerId'];
      DocumentSnapshot providerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(providerId)
          .get();

      if (providerSnapshot.exists) {
        setState(() {
          _providerName = providerSnapshot['fullName'] ?? 'Nome não disponível';
        });
      }
    } catch (e) {
      print('Error fetching provider details: $e');
    }
  }

  // Function to start the chat and create the chat room
  Future<void> _startChat() async {
    final String contratanteId = FirebaseAuth.instance.currentUser!.uid;
    final String providerId = _serviceData!['providerId'];

    // Generate chatRoomId by combining contratanteId and providerId
    String chatRoomId = contratanteId + "_" + providerId;

    try {
      DocumentSnapshot chatRoomSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomSnapshot.exists) {
        // Create the chat room
        await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).set({
          'contratanteId': contratanteId,
          'providerId': providerId,
          'createdAt': Timestamp.now(),
          'users': [contratanteId, providerId],  // Store both users
        });

        // Update chat lists for both participants
        await FirebaseFirestore.instance
            .collection('users')
            .doc(contratanteId)
            .collection('chat_list')
            .doc(chatRoomId)
            .set({
          'chatRoomId': chatRoomId,
          'lastMessage': '',
          'timestamp': Timestamp.now(),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .collection('chat_list')
            .doc(chatRoomId)
            .set({
          'chatRoomId': chatRoomId,
          'lastMessage': '',
          'timestamp': Timestamp.now(),
        });
      }

      // Navigate to the chat room
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            chatRoomId: chatRoomId,
            providerId: providerId,
            serviceId: widget.docId,
          ),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
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
                'Prestador: $_providerName', // Display provider name
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
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
              ElevatedButton(
                onPressed: _startChat, // Start chat when pressed
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.yellow[700],
                ),
                child: Text(
                  'Entrar em contato com o prestador',
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

