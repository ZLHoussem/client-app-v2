import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String password;
 
  final String createdAt;
  final Timestamp? lastLogin;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
   
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'createdAt': createdAt,
      
        
      };
}