import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateServicePage extends StatefulWidget {
  final String serviceId;
  final String providerId;

  RateServicePage({required this.serviceId, required this.providerId});

  @override
  _RateServicePageState createState() => _RateServicePageState();
}

class _RateServicePageState extends State<RateServicePage> {
  int _rating = 0;
  List<String> _elogios = [];
  bool _isSubmitting = false; // Loading state for submission

  final List<String> elogioOptions = [
    'Ótimo atendimento',
    'Muito simpático',
    'Bom trabalho',
    'Muita qualidade em serviço',
    'Ótimo papo',
    'Boa rota',
  ];

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true; // Start loading
    });

    try {
      print("Submitting rating..."); // Debug: Starting submission
      print("Service ID: ${widget.serviceId}, Provider ID: ${widget.providerId}, Rating: $_rating");

      // Store the rating in Firestore
      await FirebaseFirestore.instance.collection('ratings').add({
        'serviceId': widget.serviceId,
        'prestadorId': widget.providerId,
        'contratanteId': FirebaseAuth.instance.currentUser!.uid,
        'rating': _rating,
        'elogios': _elogios,
        'timestamp': Timestamp.now(),
      });

      print("Rating submitted successfully."); // Debug: Success

      // Update the prestador's average rating and completed service count
      await _updatePrestadorRating();

      // Update the service status in 'service_requests' to 'rated'
      await FirebaseFirestore.instance.collection('service_requests').doc(widget.serviceId).update({
        'status': 'rated',
      });

      // Show confirmation and navigate back
      setState(() {
        _isSubmitting = false; // End loading
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Obrigado pela sua avaliação!')),
      );
    } catch (e) {
      print('Error submitting rating: $e'); // Debug: Log the error
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}'); // Catch Firebase-specific error
      }
      setState(() {
        _isSubmitting = false; // End loading
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar a avaliação. Tente novamente.')),
      );
    }
  }

  Future<void> _updatePrestadorRating() async {
    try {
      print("Updating prestador's rating..."); // Debug: Start updating

      // Fetch all ratings for the prestador
      QuerySnapshot ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('prestadorId', isEqualTo: widget.providerId)
          .get();

      print("Fetched ${ratingsSnapshot.docs.length} ratings for the prestador."); // Debug: Rating count

      // Calculate the new average rating
      int totalRatings = ratingsSnapshot.docs.length;
      int sumRatings = ratingsSnapshot.docs.fold(
        0,
            (previousValue, doc) => previousValue + doc['rating'] as int,
      );
      double averageRating = sumRatings / totalRatings;

      print("New average rating: $averageRating"); // Debug: New average rating

      // Update the prestador's profile with the new rating and completed services count
      await FirebaseFirestore.instance.collection('prestadores_de_servico').doc(widget.providerId).update({
        'averageRating': averageRating,
        'completedServices': totalRatings,
      });

      print("Prestador's rating updated successfully."); // Debug: Success
    } catch (e) {
      print('Error updating prestador rating: $e'); // Debug: Log the error
    }
  }

  Widget _buildElogioOption(String elogio) {
    return ChoiceChip(
      label: Text(elogio),
      selected: _elogios.contains(elogio),
      onSelected: (bool selected) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avaliar Serviço'),
        backgroundColor: Colors.yellow[700],
      ),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator()) // Show loader while submitting
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avalie com estrelas:'),
            SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < _rating ? Colors.yellow[700] : Colors.grey,
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
              children: elogioOptions.map((elogio) => _buildElogioOption(elogio)).toList(),
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
}

