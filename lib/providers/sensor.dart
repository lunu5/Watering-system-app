import 'package:flutter/foundation.dart';

class Sensor with ChangeNotifier {
  final String id;
  List<int> temp = List.filled(12, 0);
  List<int> humid = List.filled(12, 0);
  List<int> moist = List.filled(12, 0);
  List<int> tempHis = List.filled(25, 0);
  List<int> humidHis = List.filled(25, 0);
  List<int> moistHis = List.filled(25, 0);

  Sensor({@required this.id});
}
