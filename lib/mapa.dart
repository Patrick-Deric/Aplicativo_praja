import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ServiceMapPage extends StatefulWidget {
  final String serviceName;

  ServiceMapPage({required this.serviceName});

  @override
  _ServiceMapPageState createState() => _ServiceMapPageState();
}

class _ServiceMapPageState extends State<ServiceMapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCollaborators();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  Future<Map<String, dynamic>?> _getLatLngFromCEP(String cep) async {
    // Example using 'viacep' API for Brazilian CEP, but no latitude/longitude is returned.
    // You should replace this with a geocoding API such as Google Maps Geocoding API.
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$cep&key=YOUR_GOOGLE_API_KEY';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return {
            'latitude': data['results'][0]['geometry']['location']['lat'],
            'longitude': data['results'][0]['geometry']['location']['lng'],
          };
        }
      }
    } catch (e) {
      print("Error fetching lat-lng for CEP: $e");
    }
    return null;
  }

  void _loadCollaborators() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'prestador') // Ensure fetching only service providers
        .get();

    for (var doc in snapshot.docs) {
      String cep = doc['cep'];

      // Convert CEP to lat-lng
      Map<String, dynamic>? locationData = await _getLatLngFromCEP(cep);
      if (locationData != null) {
        double latitude = locationData['latitude'];
        double longitude = locationData['longitude'];

        double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          latitude,
          longitude,
        );
        double distanceInKm = distanceInMeters / 1000;

        // Assuming 10km radius to filter the collaborators
        if (distanceInKm <= 10.0) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: doc['fullName'],
                  snippet: '${doc['jobRole']} - ${distanceInKm.toStringAsFixed(2)} km',
                ),
              ),
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Prestadores de ${widget.serviceName}'),
        backgroundColor: Colors.yellow[700],
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 12,
        ),
        markers: _markers,
      ),
    );
  }
}


