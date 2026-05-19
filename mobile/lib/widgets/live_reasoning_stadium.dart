import 'package:flutter/material.dart';
import 'dart:async';

class LiveReasoningStadium extends StatefulWidget {
  const LiveReasoningStadium({super.key});

  @override
  State<LiveReasoningStadium> createState() => _LiveReasoningStadiumState();
}

class _LiveReasoningStadiumState extends State<LiveReasoningStadium> {
  String sentinelStatus = 'Monitoring 50+ signal streams';
  String analystStatus = 'Awaiting triage artifact...';
  String commanderStatus = 'Standing by.';
  Timer? _mockStreamTimer;

  @override
  void initState() {
    super.initState();
    _startMockStreams();
  }

  void _startMockStreams() {
    // Simulate Firebase Firestore listeners for `triage_queue/*`
    _mockStreamTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final tick = timer.tick;
      setState(() {
        if (tick % 3 == 1) {
          sentinelStatus = 'Detected 5 high-confidence crisis signals (G-10)';
          analystStatus = 'Processing TriageArtifact...';
        } else if (tick % 3 == 2) {
          analystStatus = 'SituationArtifact generated. Severity: 4';
          commanderStatus = 'Planning DAG and routing updates...';
        } else {
          commanderStatus = 'ActionArtifacts emitted: 3 MCP tools executed.';
          sentinelStatus = 'Monitoring 50+ signal streams';
        }
      });
    });
  }

  @override
  void dispose() {
    _mockStreamTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStadiumHeader(),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildAgentCard(
                  icon: Icons.radar,
                  agentName: 'SENTINEL',
                  status: sentinelStatus,
                  color: Colors.blueAccent,
                  isPulsing: sentinelStatus.contains('Detected'),
                ),
                _buildAgentCard(
                  icon: Icons.psychology,
                  agentName: 'ANALYST',
                  status: analystStatus,
                  color: Colors.orangeAccent,
                  isPulsing: analystStatus.contains('Processing'),
                ),
                _buildAgentCard(
                  icon: Icons.gavel,
                  agentName: 'COMMANDER',
                  status: commanderStatus,
                  color: Colors.purpleAccent,
                  isPulsing: commanderStatus.contains('Planning'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStadiumHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'LIVE REASONING STADIUM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
          Icon(Icons.wifi_tethering, size: 16, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildAgentCard({
    required IconData icon,
    required String agentName,
    required String status,
    required Color color,
    required bool isPulsing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agentName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
