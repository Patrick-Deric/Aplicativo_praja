import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String serviceId;
  final String providerId;
  final String chatRoomId;

  ChatRoomPage({
    required this.serviceId,
    required this.providerId,
    required this.chatRoomId,
  });

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  String message = '';
  TextEditingController _messageController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  String? otherUserName;
  String? otherUserProfileUrl;
  bool _isProvider = false;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserDetails();
  }

  // Fetch the profile picture and name of the other user (contratante or prestador)
  Future<void> _fetchOtherUserDetails() async {
    String otherUserId = _isProvider ? currentUser!.uid : widget.providerId;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection(_isProvider ? 'users' : 'prestadores_de_servico')
        .doc(otherUserId)
        .get();

    if (userDoc.exists) {
      setState(() {
        otherUserName = userDoc['fullName'];
        otherUserProfileUrl = userDoc['profilePictureUrl'];
      });
    }
  }

  Future<void> _sendMessage() async {
    if (message.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'message': message,
      'senderId': currentUser!.uid,
      'receiverId': widget.providerId,
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (otherUserProfileUrl != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(otherUserProfileUrl!),
              ),
            SizedBox(width: 10),
            Text(otherUserName ?? 'Usuário'),
          ],
        ),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
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
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index];
                    bool isMe = messageData['senderId'] == currentUser!.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe && otherUserProfileUrl != null)
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(otherUserProfileUrl!),
                              ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                messageData['message'],
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Area
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue[700]),
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
