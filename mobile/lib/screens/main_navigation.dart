import 'package:flutter/material.dart';
import 'package:ciro_mobile/widgets/live_reasoning_stadium.dart';
import 'package:ciro_mobile/screens/map_screen.dart';
import 'package:ciro_mobile/widgets/twin_timeline.dart';
import 'package:ciro_mobile/screens/report_crisis_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    _buildDashboardTab(),
    const MapScreen(),
    _buildSimulatorTab(),
    const ReportCrisisScreen(),
  ];

  static Widget _buildDashboardTab() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text('CIRO HEADQUARTERS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              ),
              LiveReasoningStadium(),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSimulatorTab() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text('IMPACT SIMULATOR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              ),
              TwinTimelineWidget(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Live Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Simulator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_alert),
            label: 'Report',
          ),
        ],
      ),
    );
  }
}
