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

  @override
  void initState() {
    super.initState();
    _createOrJoinChatRoom();
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
      'lastMessage': '', // Initially empty
      'timestamp': Timestamp.now(),
    });
  }

  // Send message function
  Future<void> _sendMessage() async {
    if (message.isEmpty) return;

    final String chatRoomId = widget.chatRoomId;
    final String senderId = FirebaseAuth.instance.currentUser!.uid;
    final String receiverId = widget.providerId;

    try {
      // Send the message
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'message': message,
        'senderId': senderId,
        'receiverId': receiverId,
        'timestamp': Timestamp.now(),
      });

      // Update the chat list for both users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('chat_list')
          .doc(chatRoomId)
          .update({
        'lastMessage': message,
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('chat_list')
          .doc(chatRoomId)
          .update({
        'lastMessage': message,
        'timestamp': Timestamp.now(),
      });

      _messageController.clear(); // Clear the input after sending
    } catch (e) {
      print('Error sending message: $e');
    }
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
                  return Center(child: Text('No messages yet.'));
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
        ],
      ),
    );
  }
}

