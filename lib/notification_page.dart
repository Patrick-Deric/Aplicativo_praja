import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Center(
        child: Text('No notifications yet.'),
      ),
    );
  }
}

