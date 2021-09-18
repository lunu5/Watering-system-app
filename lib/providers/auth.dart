import 'dart:convert';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/http_exception.dart';

class Auth extends ChangeNotifier {
  String _token;
  String _userId;
  String _pumpTopic;
  String _sensorTopic;

  String get token {
    if (_token != null) return _token;
    return null;
  }

  String get pumpTopic {
    if (_pumpTopic != null) return _pumpTopic;
    return null;
  }

  String get sensorTopic {
    if (_sensorTopic != null) return _sensorTopic;
    return null;
  }

  bool get isAuth {
    return token != null;
  }

  bool get isPumpTopic {
    return pumpTopic != null;
  }

  bool get isSensorTopic {
    return sensorTopic != null;
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url =
        Uri.parse('https://watering-system468.herokuapp.com/users/login');

    try {
      final response = await http.post(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode({
            'user': email,
            'pass': password,
          }));
      final responseData = json.decode(response.body);
      print(responseData.toString());
      if (responseData['error'] == true)
        throw HttpException(responseData['message']);
      print(responseData);
      _token = responseData['token'];
      _userId = responseData['id'];
      _pumpTopic = responseData['pumpTopic'];
      _sensorTopic = responseData['sensorTopic'];
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'pumpTopic': _pumpTopic,
          'sensorTopic': _sensorTopic,
        },
      );
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> logIn(String email, String password) async {
    return _authenticate(email, password, 'login');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return false;
    final extractedUserData =
        json.decode(prefs.getString('userData')) as Map<String, Object>;
    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _pumpTopic = extractedUserData['pumpTopic'];
    _sensorTopic = extractedUserData['sensorTopic'];
    notifyListeners();
    return true;
  }

  Future<void> logOut(Function clearData) async {
    _token = null;
    _userId = null;
    _pumpTopic = null;
    _sensorTopic = null;
    clearData();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
