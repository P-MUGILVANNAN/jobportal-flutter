import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/user_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  Future<Widget> _getInitialScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    String? role = prefs.getString('role');

    if (isLoggedIn == true && role != null) {
      if (role == 'admin') {
        return AdminDashboard();
      } else {
        return UserDashboard();
      }
    }
    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show splash/loading screen while checking login state
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            // Fallback to login screen if something goes wrong
            return LoginScreen();
          }
        },
      ),
    );
  }
}
