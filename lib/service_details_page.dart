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
  String? _providerImageUrl;
  String? _providerName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  // Fetch the service details from Firestore and provider's profile picture and name
  Future<void> _fetchServiceDetails() async {
    try {
      // Fetch the service details
      DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.docId)
          .get();

      if (serviceSnapshot.exists) {
        _serviceData = serviceSnapshot.data() as Map<String, dynamic>?;

        // Fetch the provider's profile picture and name
        if (_serviceData != null) {
          String providerId = _serviceData!['providerId'];
          DocumentSnapshot providerSnapshot = await FirebaseFirestore.instance
              .collection('prestadores_de_servico')
              .doc(providerId)
              .get();

          if (providerSnapshot.exists) {
            final providerData = providerSnapshot.data() as Map<String, dynamic>?;

            if (providerData != null) {
              setState(() {
                _providerImageUrl = providerData['profilePictureUrl'];
                _providerName = providerData['fullName'] ?? 'Nome não disponível';
              });
            }
          }
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching service details: $e');
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

  // Function to request service with confirmation dialog
  Future<void> _requestService() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado!')),
      );
      return;
    }

    // Show confirmation dialog before requesting the service
    final shouldRequestService = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmação'),
          content: Text('Entre em contato antes com o prestador para requisitar o serviço. Você deseja continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User pressed 'Cancel'
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User pressed 'Continue'
              child: Text('Continuar'),
            ),
          ],
        );
      },
    );

    // If the user agrees to proceed
    if (shouldRequestService == true) {
      try {
        // Create a new service request in the Firestore database
        await FirebaseFirestore.instance.collection('service_requests').add({
          'serviceId': widget.docId,
          'providerId': _serviceData!['providerId'],
          'contratanteId': currentUser.uid,
          'status': 'pending', // Initially pending status
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Serviço requisitado com sucesso!')),
        );
      } catch (e) {
        print('Error requesting service: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao requisitar o serviço.')),
        );
      }
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
              // Display provider's profile picture if available
              CircleAvatar(
                radius: 60,
                backgroundImage: _providerImageUrl != null
                    ? NetworkImage(_providerImageUrl!)
                    : AssetImage('assets/anon.png') as ImageProvider,
              ),
              SizedBox(height: 10),

              // Display provider's name
              Text(
                _providerName ?? 'Nome não disponível',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

              // Button to start chat
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

              SizedBox(height: 10), // Space between buttons

              // New button to request service with confirmation
              ElevatedButton(
                onPressed: _requestService, // Request service with confirmation dialog
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.green[700],
                ),
                child: Text(
                  'Requisitar Serviço',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

