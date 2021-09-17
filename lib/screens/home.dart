import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/label.dart';
import '../models/mqttClientWrapper.dart';
import '../providers/pumper.dart';
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

  void setup(String topic) {
    mqttClientWrapper = MQTTClientWrapper(() => 'Hello', topic,
        Provider.of<Status>(context, listen: false).updatePumper);
    mqttClientWrapper.prepareMqttClient();
  }

  @override
  void initState() {
    final data = Provider.of<Status>(context, listen: false);
    final authData = Provider.of<Auth>(context, listen: false);
    if(mounted) setState(() {
      _isLoadingPump = true;
      _isLoadingSensor = true;
    });
    Provider.of<Status>(context, listen: false)
        .fetchAndSetPumper(authData.token)
        .then((_) {
      if(mounted) setState(() {
        _isLoadingPump = false;
      });
    });
    Provider.of<Status>(context, listen: false)
        .fetchAndSetSensor(authData.token)
        .then((_) {
      if(mounted) setState(() {
        _isLoadingSensor = false;
      });
    });
    data.addHistory();

    Timer.periodic(Duration(hours: 1), (Timer timer) {
      if(mounted) setState(() {
        data.addHistory();
      });
    });
    Timer.periodic(Duration(minutes: 1), (Timer timer) {
      if(mounted) setState(() {
        data.fetchAndSetSensor(authData.token);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    final deviceSize = MediaQuery.of(context).size;
    final authData = Provider.of<Auth>(context, listen: false);

    if (authData.isAuth) setup(authData.pumpTopic);
    // if (authData.isTopic)
    //   mqttClientWrapper.subscribeToTopic(authData.pumpTopic);

    return Scaffold(
      appBar: AppBar(
        title: Text("HOME"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
                    child: CircularProgressIndicator(),
                  )
                : Consumer<Status>(
                    child: Center(
                      child: const Text('No pump available'),
                    ),
                    builder: (ctx, data, ch) => data.pumper.length <= 0
                        ? ch
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: data.pumper.length,
                            itemBuilder: (ctx, i) => Container(
                              width: deviceSize.width * 0.12 < 100
                                  ? 100
                                  : deviceSize.width * 0.12,
                              child: Column(
                                children: [
                                  Consumer<Pumper>(
                                    builder: (ctx, pumper, _) => Switch(
                                      value: data.pumper[i].status,
                                      onChanged: (value) async {
                                        try {
                                          pumper.togglePumperStatus(
                                              authData.token,
                                              authData.userId,
                                              data.pumper[i].id);
                                          //print('old status$value');
                                          if(mounted) setState(() {
                                            data.pumper[i].status = value;
                                          });
                                          print(
                                              'status $i ${data.pumper[i].status}');
                                        } catch (error) {
                                          scaffold.showSnackBar(SnackBar(
                                            content: Text(
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
                                    'Pump $i',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
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
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Consumer<Status>(
                    child: Center(
                      child: const Text('No sensor available'),
                    ),
                    builder: (ctx, data, ch) => data.sensor.length <= 0
                        ? ch
                        : ListView.builder(
                            itemCount: data.sensor.length,
                            itemBuilder: (ctx, i) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  LineChartWidget(data.sensor[i].temp,
                                      data.sensor[i].tempHis),
                                  Label('Temperature at sensor $i'),
                                  LineChartWidget(data.sensor[i].humid,
                                      data.sensor[i].humidHis),
                                  Label('Humidity at sensor $i'),
                                  LineChartWidget(data.sensor[i].moist,
                                      data.sensor[i].moistHis),
                                  Label('Moisture at sensor $i'),
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
