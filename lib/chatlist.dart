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
        title: Text('Chats'),
        backgroundColor: Colors.yellow[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('users', arrayContains: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var chatRooms = snapshot.data!.docs;

          if (chatRooms.isEmpty) {
            return Center(
              child: Text('Nenhum chat disponível'),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              var chatRoom = chatRooms[index];
              String chatRoomId = chatRoom.id; // Get the chat room ID
              List<dynamic> users = chatRoom['users'];

              String otherUserId = users.firstWhere((userId) => userId != currentUser!.uid);
              return ListTile(
                title: Text('Chat com $otherUserId'), // Replace with fetching actual user details if needed
                onTap: () {
                  // Navigate to ChatRoomPage with the required chatRoomId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        serviceId: chatRoom['serviceId'],
                        providerId: otherUserId,
                        chatRoomId: chatRoomId, // Pass the chatRoomId correctly
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

