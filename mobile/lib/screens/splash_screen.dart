import 'package:flutter/material.dart';
import 'package:ciro_mobile/screens/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield, size: 80, color: Colors.greenAccent),
            SizedBox(height: 24),
            Text(
              'C I R O',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8.0,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Crisis Intelligence & Response Orchestrator',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              color: Colors.greenAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Initializing AI Agents...',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
