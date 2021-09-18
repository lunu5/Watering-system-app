import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/http_exception.dart';

class Pump with ChangeNotifier {
  String id;
  bool status;

  Pump({@required this.id, @required this.status});

  void _setPump(bool newstatus) {
    status = newstatus;
    notifyListeners();
  }

  Future<void> togglePumpStatus(
      String authToken, String userId, String id) async {
    final oldStatus = status;
    status = !status;
    final url =
        Uri.parse('https://watering-system468.herokuapp.com/api/setPump');
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'accept-encoding': 'gzip, deflate, br',
          'accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({"id": id, "status": status}));
    print('pump $id status: $status');
    notifyListeners();
    if (response.statusCode >= 400) {
      _setPump(oldStatus);
      throw HttpException('Could not update to server!');
    }
  }
}
