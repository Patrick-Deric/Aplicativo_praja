// user_model.dart
class UserModel {
  String uid;
  String fullName;
  String email;
  String service;
  double pricePerHour;
  bool isProvider;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.service,
    required this.pricePerHour,
    required this.isProvider,
  });

  // Method to convert UserModel to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'service': service,
      'pricePerHour': pricePerHour,
      'isProvider': isProvider,
    };
  }

  // Method to create a UserModel from a map (from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      fullName: map['fullName'],
      email: map['email'],
      service: map['service'],
      pricePerHour: map['pricePerHour'],
      isProvider: map['isProvider'],
    );
  }
}

