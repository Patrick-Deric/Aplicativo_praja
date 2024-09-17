import 'package:aplicativo_praja/ongoing_services_contratante.dart';
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
  List<Map<String, dynamic>> _filteredServices = [];
  bool _locationPermissionGranted = false;
  bool _locationServiceEnabled = false;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _loadingServices = false;

  String? _profileImageUrl;
  User? _user;

  // Selected category for filtering
  String _selectedCategory = "All";

  // List of job categories
  final List<String> _categories = [
    "All", "Pintor", "Eletricista", "Encanador", "Faxineira", "Cuidadora",
    "Pedreiro", "Marceneiro", "Motorista", "Jardineiro", "Manicure",
    "Costureira", "Técnico Informática"
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserProfile();
    _checkInternetConnection();
    _checkLocationPermissions();
    _checkPendingRatings();
  }

  Future<void> _fetchUserProfile() async {
    if (_user != null) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userSnapshot.exists && userSnapshot.data() != null) {
          setState(() {
            final data = userSnapshot.data() as Map<String, dynamic>;
            _profileImageUrl = data.containsKey('profilePictureUrl') ? data['profilePictureUrl'] : null;
          });
        }
      } catch (e) {
        print('Error fetching user profile: $e');
      }
    }
  }


  Future<void> _logoff() async {
    final bool shouldLogoff = await _showLogoffConfirmation();
    if (shouldLogoff) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<bool> _showLogoffConfirmation() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tem certeza?'),
          content: Text('Deseja realmente sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Sair'),
            ),
          ],
        );
      },
    ) ?? false;
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
      _loadNearbyProviders();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadNearbyProviders() async {
    if (_currentPosition == null ||

        _loadingServices) return;

    setState(() {
      _loadingServices = true;
    });

    try {
      final QuerySnapshot servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('status', isEqualTo: 'pending')
          .limit(50)
          .get();

      setState(() {
        _services.clear();
        _markers.clear();
      });

      for (var doc in servicesSnapshot.docs) {
        var serviceLocation = doc['location'];

        if (serviceLocation == null) {
          print('Service ${doc.id} is missing location data.');
          continue;
        }

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

      // Apply the initial category filter (default is "All")
      _applyCategoryFilter();

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
            'latitude': latitude,
            'longitude': longitude,
          });

          // Add marker based on filtered services
          if (_selectedCategory == "All" || data['serviceType'] == _selectedCategory) {
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
          }
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
        .collection('completed_services')
        .where('needsRating', isEqualTo: true)
        .where('contratanteId', isEqualTo: userId)
        .limit(5)
        .get();

    for (var service in completedServices.docs) {
      String serviceId = service.id;
      _showRatingDialog(serviceId);
    }
  }

  void _showRatingDialog(String serviceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateServicePage(serviceId: serviceId),
      ),
    );
  }

  // Apply filter based on the selected category
  void _applyCategoryFilter() {
    if (_selectedCategory == "All") {
      setState(() {
        _filteredServices = List.from(_services); // Show all services
        _markers.clear();
        _services.forEach((service) {
          _addServiceMarkerFromService(service);  // Add all markers back to the map
        });
      });
    } else {
      setState(() {
        _filteredServices = _services.where((service) {
          return service['serviceType'] == _selectedCategory;
        }).toList();

        // Filter the markers
        _markers.clear();
        _filteredServices.forEach((service) {
          _addServiceMarkerFromService(service);
        });
      });
    }
  }

  // Helper to add markers from the filtered services
  void _addServiceMarkerFromService(Map<String, dynamic> service) {
    final double latitude = service['latitude'];
    final double longitude = service['longitude'];
    final String serviceType = service['serviceType'] ?? 'Unknown';
    final double distance = service['distance'] ?? 0.0;
    final String docId = service['docId'];

    _markers

        .add(
      Marker(
        markerId: MarkerId(docId),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: serviceType,
          snippet: 'Distância: ${distance.toStringAsFixed(2)} km',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        title: Row(
          children: [
            Text('PraJá', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Spacer(),
            CircleAvatar(
              radius: 20,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : AssetImage('assets/anon.png') as ImageProvider,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
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
            ),
            SizedBox(height: 20),
            // Job categories horizontal ListView
            Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _applyCategoryFilter();
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 16),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _selectedCategory == category ? Colors.yellow[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            category,
                            style: TextStyle(
                              color: _selectedCategory == category ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _filteredServices.isEmpty
                  ? Center(child: Text('Nenhum serviço encontrado'))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _filteredServices.length,
                itemBuilder: (context, index) {
                  final service = _filteredServices[index];
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
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => OngoingServicesContratantePage()));
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListPage()));
          } else if (index == 3) {
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
          margin: const EdgeInsets.symmetric(vertical: 10),
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
    'Pretensão: $salaryRange por hora',
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
    ));
    }
}
