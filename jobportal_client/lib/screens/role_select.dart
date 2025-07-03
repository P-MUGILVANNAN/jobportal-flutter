import 'package:flutter/material.dart';
import 'user_dashboard.dart';
import 'admin_dashboard.dart';

class RoleSelectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Who are you?", style: TextStyle(fontSize: 20)),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text("Job Seeker"),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserDashboard())),
            ),
            ElevatedButton(
              child: Text("Admin"),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboard())),
            ),
          ],
        ),
      ),
    );
  }
}