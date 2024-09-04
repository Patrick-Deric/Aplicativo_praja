import 'package:flutter/material.dart';

class ServiceDetailsPage extends StatelessWidget {
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
