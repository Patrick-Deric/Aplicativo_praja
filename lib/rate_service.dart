import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateServicePage extends StatefulWidget {
  final String serviceId;

  RateServicePage({required this.serviceId});

  @override
  _RateServicePageState createState() => _RateServicePageState();
}

class _RateServicePageState extends State<RateServicePage> {
  int _rating = 0;
  List<String> _elogios = [];
  bool _isSubmitting = false;
  String? _providerId; // Fetch this from Firestore
  String? _errorMessage;

  final List<String> elogioOptions = [
    'Ótimo atendimento',
    'Muito simpático',
    'Bom trabalho',
    'Muita qualidade em serviço',
  ];

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails(); // Fetch service details when the page loads
  }

  // Fetch service details from Firestore
  Future<void> _fetchServiceDetails() async {
    try {
      DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('completed_services')
          .doc(widget.serviceId)
          .get();

      if (serviceSnapshot.exists) {
        final serviceData = serviceSnapshot.data() as Map<String, dynamic>?;

        if (serviceData != null && serviceData.containsKey('providerId')) {
          setState(() {
            _providerId = serviceData['providerId'];
          });
        } else {
          setState(() {
            _errorMessage = 'Erro: Não foi possível carregar o serviço.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar detalhes do serviço: $e';
      });
    }
  }

  Future<void> _submitRating() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado!')),
      );
      return;
    }

    // Immediately pop to go back to the previous page
    Navigator.of(context).pop(); // Act as a back button

    // Submit the rating in the background
    try {
      setState(() {
        _isSubmitting = true; // Indicate the form is being submitted
      });

      // Add rating to the 'ratings' collection
      await FirebaseFirestore.instance.collection('ratings').add({
        'serviceId': widget.serviceId,
        'providerId': _providerId,
        'contratanteId': currentUser.uid,
        'rating': _rating,
        'elogios': _elogios,
        'timestamp': Timestamp.now(),
      });

      // Check if the service has already been rated
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('serviceId', isEqualTo: widget.serviceId)
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        // Update the 'needsRating' field to false in the 'completed_services' collection
        await FirebaseFirestore.instance
            .collection('completed_services')
            .doc(widget.serviceId)
            .update({
          'needsRating': false,
        });
      }
    } catch (e) {
      // Log the error but don't show a message to the user
      print('Erro ao enviar a avaliação: $e');
    } finally {
      setState(() {
        _isSubmitting = false; // Reset the submitting state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avaliar Serviço', style: TextStyle(color: Colors.white, fontSize: 16)) ,
        backgroundColor: Colors.yellow[700],

      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avalie com estrelas:'),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < _rating
                        ? Colors.yellow[700]
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 20),
            Text('Escolha um elogio:'),
            Wrap(
              spacing: 10.0,
              runSpacing: 5.0,
              children: elogioOptions
                  .map((elogio) => _buildElogioOption(elogio))
                  .toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _rating > 0 ? _submitRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text('Enviar Avaliação'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElogioOption(String elogio) {
    return ChoiceChip(
      label: Text(elogio),
      selected: _elogios.contains(elogio),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _elogios.add(elogio);
          } else {
            _elogios.remove(elogio);
          }
        });
      },
    );
  }
}


