import 'package:flutter/material.dart';

class RouteConfirmScreen extends StatelessWidget {
  const RouteConfirmScreen({super.key});

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Confirm'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the home screen when the button is pressed
            Navigator.pushNamed(context, '/home');
          },
          child: const Text('Go to Home Screen'),
        ),
      ),
    );
  }
}