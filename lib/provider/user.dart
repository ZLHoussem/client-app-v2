import 'package:flutter/material.dart';


class UserProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

void setUserId(String userId) {
  if (userId.trim().isEmpty) {
    throw ArgumentError('User ID cannot be empty or whitespace');
  }
  _userId = userId;
  notifyListeners();
}

void clearUserId() {
  _userId = null;
  notifyListeners();
}
}