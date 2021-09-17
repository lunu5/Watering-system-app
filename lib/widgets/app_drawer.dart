import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watering_system/screens/home.dart';
import '../providers/auth.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: Text('Hello'),
            automaticallyImplyLeading: false,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Shop'),
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Orders'),
            onTap: () => Navigator.of(context).pushReplacementNamed(Homepage.routeName),
          ),
        ],
      ),
    );
  }
}
