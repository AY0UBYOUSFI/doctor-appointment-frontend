import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 4 seconds
    Future.delayed(const Duration(seconds: 16), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Online GIF from a URL
            CachedNetworkImage(
              imageUrl:
                  'https://mir-s3-cdn-cf.behance.net/project_modules/disp/a85933109776109.5fdb5df5c3c18.gif', // Replace with your GIF URL
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  CircularProgressIndicator(), // Loading indicator
              errorWidget: (context, url, error) =>
                  Icon(Icons.error), // Fallback if loading fails
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
