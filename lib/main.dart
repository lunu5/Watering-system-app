import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pumper.dart';
import 'providers/auth.dart';
import 'providers/status.dart';
import 'screens/auth_screen.dart';
import 'screens/home.dart';
import 'screens/splash_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Auth(),
        ),
        ChangeNotifierProvider.value(
          value: Status(),
        ),
        ChangeNotifierProvider.value(
          value: Pumper(id: null, status: false),
        ),
      ],
      child: Consumer<Auth>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Watering system',
          theme: ThemeData(
            primarySwatch: Colors.green,
            accentColor: Colors.lightGreenAccent,
            fontFamily: 'Lato',
          ),
          debugShowCheckedModeBanner:false,
          home: auth.isAuth
              ? Homepage()
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, authResultSnapshot) =>
                      authResultSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? SplashScreen()
                          : AuthScreen(),
                ),
          initialRoute: AuthScreen.routeName,
          routes: {
            AuthScreen.routeName: (ctx) => AuthScreen(),
            Homepage.routeName: (ctx) => Homepage(),
          },
        ),
      ),
    );
  }
}
