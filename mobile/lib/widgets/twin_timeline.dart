import 'package:flutter/material.dart';

class TwinTimelineWidget extends StatelessWidget {
  const TwinTimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // This represents the counterfactual simulator visual output
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Colors.white24),
          Row(
            children: [
              Expanded(child: _buildTimelineSide(
                title: 'WITHOUT CIRO',
                color: Colors.redAccent,
                delay: '45 mins',
                trapped: '89 persons',
                desc: 'Standard manual detection & delayed response.',
              )),
              Container(width: 1, height: 200, color: Colors.white24),
              Expanded(child: _buildTimelineSide(
                title: 'WITH CIRO',
                color: Colors.greenAccent,
                delay: '5 mins',
                trapped: '12 persons',
                desc: 'AI early warning & instant rerouting.',
              )),
            ],
          ),
          const Divider(height: 1, color: Colors.white24),
          _buildImpactFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('COUNTERFACTUAL SIMULATOR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          Icon(Icons.compare_arrows, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildTimelineSide({
    required String title,
    required Color color,
    required String delay,
    required String trapped,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _Stat(label: 'Avg Delay', value: delay, color: color),
          const SizedBox(height: 12),
          _Stat(label: 'At Risk', value: trapped, color: color),
          const SizedBox(height: 16),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildImpactFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.save_alt, color: Colors.greenAccent),
          SizedBox(width: 8),
          Text(
            '14,820 Person-Minutes Saved',
            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}
