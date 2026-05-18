import 'package:flutter/material.dart';

class LiveReasoningStadium extends StatelessWidget {
  const LiveReasoningStadium({super.key});

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
                  status: 'Monitoring 50+ signal streams',
                  color: Colors.blueAccent,
                  isPulsing: true,
                ),
                _buildAgentCard(
                  icon: Icons.psychology,
                  agentName: 'ANALYST',
                  status: 'Awaiting triage artifact...',
                  color: Colors.orangeAccent,
                  isPulsing: false,
                ),
                _buildAgentCard(
                  icon: Icons.gavel,
                  agentName: 'COMMANDER',
                  status: 'Standing by.',
                  color: Colors.purpleAccent,
                  isPulsing: false,
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
