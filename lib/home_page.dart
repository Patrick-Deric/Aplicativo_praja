import 'package:aplicativo_praja/ongoing_services.dart';
import 'package:aplicativo_praja/profile_contratante.dart';
import 'package:aplicativo_praja/rate_service.dart';
import 'package:aplicativo_praja/service_details_page.dart';
import 'package:aplicativo_praja/profile_page.dart';
import 'package:aplicativo_praja/login_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'chatlist.dart';
import 'ongoing_services_contratante.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _currentPosition;
  final double searchRadiusKm = 10.0;
  List<Map<String, dynamic>> _services = [];
  bool _locationPermissionGranted = false;
  bool _locationServiceEnabled = false;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _loadingServices = false;  // Keep track of loading state

  Future<void> _logoff() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _checkLocationPermissions();
    _checkPendingRatings();
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor, verifique sua conexão com a internet.'),
      ));
    }
  }

  Future<void> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() {
        _locationPermissionGranted = true;
      });
      _checkLocationServices();
    } else {
      setState(() {
        _locationPermissionGranted = false;
      });
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permissão de Localização"),
        content: Text("Por favor, permita o acesso à localização para usar o mapa."),
        actions: <Widget>[
          TextButton(
            child: Text("Ok"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocationServices() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (_locationServiceEnabled) {
      _getCurrentLocation();
    } else {
      setState(() {
        _locationServiceEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor, ative os serviços de localização.'),
      ));
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted || !_locationServiceEnabled) return;

    try {
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _loadNearbyProviders(); // Load nearby providers and services
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadNearbyProviders() async {
    if (_currentPosition == null || _loadingServices) return; // Avoid loading multiple times

    setState(() {
      _loadingServices = true;
    });

    try {
      // Fetch all pending services
      final QuerySnapshot servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('status', isEqualTo: 'pending') // Only fetch pending services
          .limit(50)  // Limit to avoid performance issues
          .get();

      // Clear services before loading new ones
      setState(() {
        _services.clear();
        _markers.clear();
      });

      for (var doc in servicesSnapshot.docs) {
        var serviceLocation = doc['location'];

        // Validate the service location before adding markers
        if (serviceLocation == null) {
          print('Service ${doc.id} is missing location data.');
          continue;
        }

        // Check the type and parse location accordingly
        if (serviceLocation is GeoPoint) {
          _addServiceMarker(serviceLocation.latitude, serviceLocation.longitude, doc);
        } else if (serviceLocation is String && serviceLocation.contains(',')) {
          List<String> latLng = serviceLocation.split(',');
          double latitude = double.parse(latLng[0]);
          double longitude = double.parse(latLng[1]);

          _addServiceMarker(latitude, longitude, doc);
        } else {
          print("Invalid or missing location data for service: ${doc.id}");
        }
      }

      print("Services loaded: ${_services.length}"); // Log service count
    } catch (e) {
      print('Error loading services: $e');
    } finally {
      setState(() {
        _loadingServices = false;
      });
    }
  }

  void _addServiceMarker(double latitude, double longitude, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        latitude,
        longitude,
      );
      double distanceInKm = distanceInMeters / 1000;

      if (distanceInKm <= searchRadiusKm) {
        setState(() {
          _services.add({
            'serviceType': data['serviceType'] ?? 'Unknown',
            'availableDates': _formatAvailableDates(data['availableDates']),
            'salaryRange': data['salaryRange'] ?? 'Unknown',
            'distance': distanceInKm,
            'docId': doc.id,
            'providerId': data['providerId'],
          });

          _markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: data['serviceType'] ?? 'Unknown',
                snippet: 'Distância: ${distanceInKm.toStringAsFixed(2)} km',
              ),
            ),
          );
        });
      }
    }
  }

  String _formatAvailableDates(List<dynamic>? availableDates) {
    if (availableDates == null || availableDates.isEmpty) return 'No dates available';
    DateTime startDate = DateTime.parse(availableDates.first);
    DateTime endDate = DateTime.parse(availableDates.last);
    return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}';
  }

  Future<void> _checkPendingRatings() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot completedServices = await FirebaseFirestore.instance
        .collection('service_requests')
        .where('status', isEqualTo: 'completed')
        .where('contratanteId', isEqualTo: userId)
        .limit(5)  // Limit to avoid heavy queries
        .get();

    for (var service in completedServices.docs) {
      String serviceId = service.id;
      String providerId = service['providerId'];

      QuerySnapshot ratingSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('serviceId', isEqualTo: serviceId)
          .get();

      if (ratingSnapshot.docs.isEmpty) {
        _showRatingDialog(serviceId, providerId);
      }
    }
  }

  void _showRatingDialog(String serviceId, String providerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateServicePage(serviceId: serviceId, providerId: providerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        title: Row(
          children: [
            Text('PJ', style: TextStyle(color: Colors.white)),
            Spacer(),
            CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.jpg'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logoff,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.yellow[700],
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Minhas Conversas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatListPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar Serviços',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.yellow[100],
                ),
                child: Stack(
                  children: [
                    if (_currentPosition != null && _locationPermissionGranted)
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 12,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                    if (!_locationPermissionGranted)
                      Center(
                        child: Text(
                          'Por favor, permita o acesso à localização para ver o mapa.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (!_locationServiceEnabled)
                      Center(
                        child: Text(
                          'Ative os serviços de localização para usar o mapa.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _services.isEmpty
                  ? Center(child: Text('Nenhum serviço encontrado'))
                  : GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return _buildServiceCard(
                    context,
                    serviceName: service['serviceType'] ?? 'Serviço',
                    serviceDescription: service['availableDates'] ?? 'Descrição',
                    distance: service['distance'] ?? 0.0,
                    salaryRange: service['salaryRange'] ?? 'Unknown',
                    docId: service['docId'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.yellow[700],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Serviços'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => OngoingServicesContratantePage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileContratantePage()));
          }
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context,
      {required String serviceName, required String serviceDescription, required double distance, required String salaryRange, required String docId}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsPage(docId: docId, distance: distance),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: AssetImage('assets/service.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                serviceName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                serviceDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 5),
              Text(
                'Pretensão: $salaryRange',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
              Text(
                'Distância: ${distance.toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.yellow[700]),
              ),
              SizedBox(height: 5),
              Text(
                'Pressione para mais detalhes',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


