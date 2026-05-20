import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:ciro_mobile/widgets/confirmed_disasters_provider.dart';

class LiveReasoningStadium extends ConsumerStatefulWidget {
  const LiveReasoningStadium({super.key});

  @override
  ConsumerState<LiveReasoningStadium> createState() => _LiveReasoningStadiumState();
}

class _LiveReasoningStadiumState extends ConsumerState<LiveReasoningStadium> {
  String sentinelStatus = 'Monitoring 50+ signal streams';
  String analystStatus = 'Awaiting triage artifact...';
  String commanderStatus = 'Standing by.';
  Timer? _mockStreamTimer;

  @override
  void initState() {
    super.initState();
    // Start simulation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMockStreams();
    });
  }

  void _startMockStreams() {
    _mockStreamTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final tick = timer.tick;
      setState(() {
        if (tick % 3 == 1) {
          sentinelStatus = 'Detected 5 high-confidence crisis signals (G-10)';
          analystStatus = 'Processing TriageArtifact...';
          commanderStatus = 'Standing by.';

          // Publish Sentinel alert to provider
          final disaster = generateMockDisaster(
            id: 'g10_flood',
            title: 'G-10 Flash Flood',
            type: 'Urban Flooding',
            location: 'G-10 Markaz, Islamabad',
            lat: 33.6938,
            lng: 72.9910,
            confidence: 94.2,
            severity: 4,
            status: 'Sentinel Triaged',
          );
          ref.read(confirmedDisastersProvider.notifier).addDisaster(disaster);
          ref.read(activeDisasterIdProvider.notifier).state = 'g10_flood';
        } else if (tick % 3 == 2) {
          analystStatus = 'SituationArtifact generated. Severity: 4';
          commanderStatus = 'Planning DAG and routing updates...';

          // Update state to Analyst stage
          ref.read(confirmedDisastersProvider.notifier).updateStatus('g10_flood', 'Analyst Assessed (Confidence: 98.4%)');
        } else {
          commanderStatus = 'ActionArtifacts emitted: 3 MCP tools executed.';
          sentinelStatus = 'Monitoring 50+ signal streams';

          // Update state to Commander finalized
          ref.read(confirmedDisastersProvider.notifier).updateStatus('g10_flood', 'Commander Dispatched & Routed');
          
          // Seed another disaster once in a while to make the dashboard look like a hub!
          if (tick >= 6) {
            final secondDisaster = generateMockDisaster(
              id: 'khi_heatwave',
              title: 'Karachi Heatwave emergency',
              type: 'Heatwave Crisis',
              location: 'Clifton, Karachi',
              lat: 24.8607,
              lng: 67.0011,
              confidence: 97.8,
              severity: 5,
              status: 'Active Monitoring',
            );
            ref.read(confirmedDisastersProvider.notifier).addDisaster(secondDisaster);
          }
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
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.9),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStadiumHeader(),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                _buildAgentCard(
                  icon: Icons.radar,
                  agentName: 'SENTINEL',
                  status: sentinelStatus,
                  color: const Color(0xFF00E5FF), // Cyber Cyan
                  isPulsing: sentinelStatus.contains('Detected'),
                ),
                _buildAgentCard(
                  icon: Icons.psychology,
                  agentName: 'ANALYST',
                  status: analystStatus,
                  color: const Color(0xFFFF007F), // Neon Magenta
                  isPulsing: analystStatus.contains('Processing'),
                ),
                _buildAgentCard(
                  icon: Icons.gavel,
                  agentName: 'COMMANDER',
                  status: commanderStatus,
                  color: const Color(0xFF39FF14), // Lime Green
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
          Icon(Icons.wifi_tethering, size: 16, color: Colors.greenAccent),
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: isPulsing
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    onEnd: () {},
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(icon, size: 16, color: color),
                      );
                    },
                  )
                : Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      agentName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (isPulsing) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
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
