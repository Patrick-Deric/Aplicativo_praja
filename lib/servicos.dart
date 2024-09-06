import 'package:flutter/material.dart';

import 'mapa.dart';

class ServiceDetail extends StatelessWidget {
  final String serviceName;
  final String serviceImage;

  ServiceDetail({required this.serviceName, required this.serviceImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          Image.asset(serviceImage, fit: BoxFit.cover),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServiceMapPage(serviceName: serviceName)),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              backgroundColor: Colors.grey[800],
            ),
            child: Text(
              'Ver prestadores próximos',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}