import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String serviceId;
  final String providerId;
  final String chatRoomId; // Passed from previous page

  ChatRoomPage({
    required this.serviceId,
    required this.providerId,
    required this.chatRoomId, // Pass it in the constructor
  });

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  String message = '';
  TextEditingController _messageController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isProvider = false;
  bool _hasAcceptedService = false; // To track if the service was accepted

  @override
  void initState() {
    super.initState();
    _checkIfProvider();
    _checkIfServiceAccepted(); // Check if service has already been accepted
    _createOrJoinChatRoom();
  }

  // Check if the current user is the provider
  Future<void> _checkIfProvider() async {
    setState(() {
      _isProvider = currentUser!.uid == widget.providerId;
    });
  }

  // Check if the service has already been accepted
  Future<void> _checkIfServiceAccepted() async {
    final requestSnapshot = await FirebaseFirestore.instance
        .collection('service_requests')
        .where('serviceId', isEqualTo: widget.serviceId)
        .where('providerId', isEqualTo: widget.providerId)
        .where('contratanteId', isEqualTo: currentUser!.uid)
        .get();

    if (requestSnapshot.docs.isNotEmpty) {
      final requestStatus = requestSnapshot.docs.first['status'];
      if (requestStatus == 'ongoing' || requestStatus == 'completed') {
        setState(() {
          _hasAcceptedService = true;
        });
      }
    }
  }

  // Create or join a chat room
  Future<void> _createOrJoinChatRoom() async {
    final roomSnapshot = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .get();

    if (!roomSnapshot.exists) {
      // Create the chat room if it doesn't exist
      await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).set({
        'createdAt': Timestamp.now(),
        'contratanteId': currentUser!.uid, // Include contratanteId
        'providerId': widget.providerId,   // Include providerId
        'users': [currentUser!.uid, widget.providerId],
      });
    }

    // Add the chat room to the contratante's chat list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('chat_list')
        .doc(widget.chatRoomId)
        .set({
      'chatRoomId': widget.chatRoomId,
      'providerId': widget.providerId,
      'contratanteId': currentUser!.uid,
      'lastMessage': '', // Initially empty, can be updated later
      'timestamp': Timestamp.now(),
    });

    // Add the chat room to the provider's chat list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.providerId)
        .collection('chat_list')
        .doc(widget.chatRoomId)
        .set({
      'chatRoomId': widget.chatRoomId,
      'contratanteId': currentUser!.uid,
      'providerId': widget.providerId,
      'lastMessage': '', // Initially empty
      'timestamp': Timestamp.now(),
    });
  }

  // Accept the service request
  Future<void> _acceptServiceRequest() async {
    try {
      final requestSnapshot = await FirebaseFirestore.instance
          .collection('service_requests')
          .where('serviceId', isEqualTo: widget.serviceId)
          .where('providerId', isEqualTo: widget.providerId)
          .where('contratanteId', isEqualTo: currentUser!.uid)
          .get();

      if (requestSnapshot.docs.isNotEmpty) {
        final requestId = requestSnapshot.docs.first.id;

        // Update the status to 'ongoing' in service_requests
        await FirebaseFirestore.instance.collection('service_requests').doc(requestId).update({
          'status': 'ongoing',
        });

        // Update the service status in the services collection
        await FirebaseFirestore.instance.collection('services').doc(widget.serviceId).update({
          'status': 'ongoing',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Serviço aceito e agora está em andamento!')),
        );

        setState(() {
          _hasAcceptedService = true; // Mark the service as accepted
        });
      }
    } catch (e) {
      print('Erro ao aceitar o serviço: $e');
    }
  }

  // Send message function
  Future<void> _sendMessage() async {
    if (message.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId) // Use the chatRoomId from the widget
        .collection('messages')
        .add({
      'message': message,
      'senderId': currentUser!.uid,
      'receiverId': widget.providerId,
      'timestamp': Timestamp.now(),
    });

    // Update the chat list for both users with the last message
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('chat_list')
        .doc(widget.chatRoomId)
        .update({
      'lastMessage': message,
      'timestamp': Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.providerId)
        .collection('chat_list')
        .doc(widget.chatRoomId)
        .update({
      'lastMessage': message,
      'timestamp': Timestamp.now(),
    });

    _messageController.clear(); // Clear the text field after sending
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat com Prestador'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId) // Use the chatRoomId from the widget
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(child: Text('Nenhuma mensagem ainda.'));
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index];
                    bool isMe = messageData['senderId'] == currentUser!.uid;

                    return ListTile(
                      title: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            messageData['message'],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (value) {
                      setState(() {
                        message = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),

          // Button to accept service (only visible for provider if not already accepted)
          if (_isProvider && !_hasAcceptedService)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _acceptServiceRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Aceitar Serviço'),
              ),
            ),
        ],
      ),
    );
  }
}
