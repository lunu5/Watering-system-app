import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pumper.dart';
import 'sensor.dart';

class Status with ChangeNotifier {
  List<Pumper> _pumper = [];
  List<Sensor> _sensor = [];

  List<Pumper> get pumper {
    return [..._pumper];
  }

  List<Sensor> get sensor {
    return [..._sensor];
  }

  Pumper findPumper(String id) {
    return _pumper.firstWhere((pumper) => pumper.id == id);
  }

  Sensor findSensor(String id) {
    return _sensor.firstWhere((sensor) => sensor.id == id);
  }

  Future<List<dynamic>> fetchAndSetData(String object, String token,
      [bool filterByUser = false]) async {
    var url = Uri.parse(
        'https://watering-system468.herokuapp.com/api/getLatest${object}Data');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'accept-encoding': 'gzip, deflate, br',
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final data = json.decode(response.body) as List<dynamic>;
    //print('Leglth is 2 $data');
    if (data == null) return null;
    return data;
  }

  Future<void> fetchAndSetPumper(String token,
      [bool filterByUser = false]) async {
    try {
      var url = Uri.parse(
          'https://watering-system468.herokuapp.com/api/getLatestPumpData');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'accept-encoding': 'gzip, deflate, br',
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = json.decode(response.body) as List<dynamic>;
      updatePumper(data);
      //print('Leglth is ${_pumper.length}');
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> fetchAndSetSensor(String token,
      [bool filterByUser = false]) async {
    try {
      var url = Uri.parse(
          'https://watering-system468.herokuapp.com/api/getLatestSensorData');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'accept-encoding': 'gzip, deflate, br',
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final data = json.decode(response.body) as Map<String, dynamic>;
      //print('Sensor data is $data');
      //List<Sensor> loadedSensors = [];
      data.forEach((key, value) {
        //print('key $key, sensor $value');
        value.forEach((sensor) {
          if (_sensor.length < value.length) {
            if ((_sensor.length + 1).toString() == sensor['id'])
              _sensor.add(Sensor(id: sensor['id']));
            //print('sensor id ${sensor['id']}');
          }
          switch (key) {
            case "tempArr":
              var element =
                  _sensor.firstWhere((element) => element.id == sensor['id']);
              _sensor.firstWhere((element) => element.id == sensor['id']).temp =
                  _updateList(sensor['data'], element.temp);
              //print('temp key ${_sensor.length}/${value.length}/$sensor');
              break;
            case "humiArr":
              var element =
                  _sensor.firstWhere((element) => element.id == sensor['id']);
              _sensor
                  .firstWhere((element) => element.id == sensor['id'])
                  .humid = _updateList(sensor['data'], element.humid);
              //print('humid key ${_sensor.length}/${value.length}/$sensor');
              break;
            case "moisArr":
              var element =
                  _sensor.firstWhere((element) => element.id == sensor['id']);
              //_updateList(sensor['data'], element.moist);
              _sensor
                  .firstWhere((element) => element.id == sensor['id'])
                  .moist = _updateList(sensor['data'], element.moist);
              //print('moist key ${_sensor.length}/${value.length}/$sensor');
              break;
            default:
          }
        });
      });
      notifyListeners();
    } catch (error) {
      print('error sensor : $error');
      throw error;
    }
  }

  List<int> _updateList(int data, List<int> list) {
    list = [...list, data];
    list.removeAt(0);
    return list;
  }

  void addHistory() {
    _sensor.forEach((element) {
      element.tempHis = _updateList(element.temp.last, element.tempHis);
      element.humidHis = _updateList(element.humid.last, element.humidHis);
      element.moistHis = _updateList(element.moist.last, element.moistHis);
    });
  }

  void updatePumper(List<dynamic> pump) {
    List<Pumper> loadedPumpers = [];
    pump.forEach((pumper) {
      loadedPumpers.add(Pumper(id: pumper['id'], status: pumper['status']));
    });
    _pumper = loadedPumpers;
    notifyListeners();
  }

  void logOut() {
    _pumper = [];
    _sensor = [];
    notifyListeners();
  }
}
