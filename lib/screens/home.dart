import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/label.dart';
import '../models/mqttClientWrapper.dart';
import '../providers/pump.dart';
import '../widgets/line_chart.dart';
import '../providers/status.dart';
import '../providers/auth.dart';
import 'auth_screen.dart';

class Homepage extends StatefulWidget {
  static const routeName = '/home';

  const Homepage({key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  MQTTClientWrapper mqttClientWrapper;
  var _isLoadingPump = false;
  var _isLoadingSensor = false;

  void setup(String pumpTopic, String sensorTopic) {
    mqttClientWrapper = MQTTClientWrapper(
        pumpTopic: pumpTopic,
        sensorTopic: sensorTopic,
        onPumpChanged: Provider.of<Status>(context, listen: false).updatePump,
        onSensorChanged:
            Provider.of<Status>(context, listen: false).updateSensor);
    mqttClientWrapper.prepareMqttClient();
  }

  @override
  void initState() {
    final data = Provider.of<Status>(context, listen: false);
    final authData = Provider.of<Auth>(context, listen: false);
    if (mounted)
      setState(() {
        _isLoadingPump = true;
        _isLoadingSensor = true;
      });
    Provider.of<Status>(context, listen: false)
        .fetchAndSetPump(authData.token)
        .then((_) {
      if (mounted)
        setState(() {
          _isLoadingPump = false;
        });
    });
    Provider.of<Status>(context, listen: false)
        .fetchAndSetSensor(authData.token)
        .then((_) {
      if (mounted)
        setState(() {
          _isLoadingSensor = false;
        });
    });
    data.addHistory();

    Timer.periodic(Duration(hours: 1), (Timer timer) {
      if (mounted)
        setState(() {
          data.addHistory();
        });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    final deviceSize = MediaQuery.of(context).size;
    final authData = Provider.of<Auth>(context, listen: false);

    if (authData.isAuth) setup(authData.pumpTopic, authData.sensorTopic);
    // if (authData.isTopic)
    //   mqttClientWrapper.subscribeToTopic(authData.pumpTopic);

    return Scaffold(
      appBar: AppBar(
        title: const Text("HOME"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
              await authData
                  .logOut(Provider.of<Status>(context, listen: false).logOut);
            },
          ),
        ],
      ),
      drawer: null,
      body: Column(
        children: [
          Container(
            height:
                deviceSize.height * 0.12 < 75 ? 75 : deviceSize.height * 0.12,
            child: _isLoadingPump
                ? Center(
                    child: const CircularProgressIndicator(),
                  )
                : Consumer<Status>(
                    child: const Center(
                      child: const Text(
                        'No pump available',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    builder: (ctx, data, ch) => data.pump.length <= 0
                        ? ch
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: data.pump.length,
                            itemBuilder: (ctx, i) => Container(
                              width: deviceSize.width * 0.12 < 100
                                  ? 100
                                  : deviceSize.width * 0.12,
                              child: Column(
                                children: [
                                  Consumer<Pump>(
                                    builder: (ctx, pump, _) => Switch(
                                      value: data.pump[i].status,
                                      onChanged: (value) async {
                                        try {
                                          pump.togglePumpStatus(authData.token,
                                              authData.userId, data.pump[i].id);
                                          //print('old status$value');
                                          if (mounted)
                                            setState(() {
                                              data.pump[i].status = value;
                                            });
                                          print(
                                              'status $i ${data.pump[i].status}');
                                        } catch (error) {
                                          scaffold.showSnackBar(SnackBar(
                                            content: const Text(
                                              'Update pump status failed!',
                                              textAlign: TextAlign.center,
                                            ),
                                          ));
                                        }
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Pump ${i + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
          ),
          Flexible(
            child: _isLoadingSensor
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Consumer<Status>(
                    child: const Center(
                      child: const Text(
                        'No sensor available',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    builder: (ctx, data, ch) => data.sensor.length <= 0
                        ? ch
                        : ListView.builder(
                            itemCount: data.sensor.length,
                            itemBuilder: (ctx, i) => Container(
                              margin: deviceSize.width > deviceSize.height * 1.5
                                  ? EdgeInsets.symmetric(
                                      horizontal: deviceSize.height * 0.4)
                                  : EdgeInsets.symmetric(
                                      horizontal: deviceSize.width * 0.05),
                              child: Column(
                                children: [
                                  LineChartWidget(data.sensor[i].temp,
                                      data.sensor[i].tempHis),
                                  Label('Temperature at sensor ${i + 1}'),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  LineChartWidget(data.sensor[i].humid,
                                      data.sensor[i].humidHis),
                                  Label('Humidity at sensor ${i + 1}'),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  LineChartWidget(data.sensor[i].moist,
                                      data.sensor[i].moistHis),
                                  Label('Moisture at sensor ${i + 1}'),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
