import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatroom.dart'; // Import your chat room page
import 'home_page.dart';
import 'ongoing_services_contratante.dart';
import 'profile_contratante.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  int _selectedIndex = 2; // Set this to 2 since Chat is the third item

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
              var chatData = chatList[index].data() as Map<String, dynamic>;
              var chatRoomId = chatData['chatRoomId'];

              // Fetch the latest message from the messages subcollection
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1) // Only get the last message
                    .snapshots(),
                builder: (context, messageSnapshot) {
                  if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
                    return Container(); // No messages yet
                  }

                  var lastMessageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  var lastMessage = lastMessageData['text'] ?? '';

                  // Determine if this chat is with a provider or contratante
                  var otherUserId = chatData.containsKey('providerId')
                      ? chatData['providerId']
                      : chatData['contratanteId'];

                  // Fetch the other user's profile
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection(chatData.containsKey('providerId')
                        ? 'prestadores_de_servico'
                        : 'users')
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return ListTile(
                          title: Text('Carregando...'),
                        );
                      }

                      var otherUser = userSnapshot.data!.data() as Map<String, dynamic>;
                      var otherUserName = otherUser['fullName'] ?? 'Usuário';
                      var otherUserProfilePic = otherUser['profilePictureUrl'] ?? null;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: otherUserProfilePic != null
                              ? NetworkImage(otherUserProfilePic)
                              : AssetImage('assets/anon.png') as ImageProvider,
                        ),
                        title: Text(
                          otherUserName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage.isNotEmpty ? lastMessage : 'Sem mensagens',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          // Navigate to the chat room page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomPage(
                                chatRoomId: chatRoomId,
                                providerId: otherUserId,
                                serviceId: chatRoomId, // If you need to pass the service ID
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
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Set the selected index
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
            // Navigate to the home page if necessary
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
}

