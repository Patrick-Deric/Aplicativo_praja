import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom.dart'; // Import your chat room page

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Conversas'),
        backgroundColor: Colors.yellow[700],
      ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('chat_list')
              .orderBy('timestamp', descending: true) // Order by latest message
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var chatList = snapshot.data!.docs;

            if (chatList.isEmpty) {
              return Center(child: Text('Nenhuma conversa encontrada.'));
            }

            return ListView.builder(
              itemCount: chatList.length,
              itemBuilder: (context, index) {
                var chatData = chatList[index];
                var otherUserId = chatData['providerId'] ?? chatData['contratanteId'];
                var lastMessage = chatData['lastMessage'] ?? '';

                // Fetch the other user's information to display their name
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return ListTile(
                        title: Text('Carregando...'),
                      );
                    }

                    var otherUser = userSnapshot.data;
                    var otherUserName = otherUser!['fullName'] ?? 'Usuário';

                    return ListTile(
                      title: Text(otherUserName),
                      subtitle: Text(lastMessage),
                      onTap: () {
                        // Navigate to the chat room page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(
                              chatRoomId: chatData['chatRoomId'],
                              providerId: otherUserId,
                              serviceId: chatData['chatRoomId'],  // If you need to pass the service ID
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        )
    );
  }
}


