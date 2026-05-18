import 'package:flutter/material.dart';

class CrisisMemoryPanel extends StatelessWidget {
  final List<Map<String, dynamic>> historicalMatches;

  const CrisisMemoryPanel({
    super.key,
    required this.historicalMatches,
  });

  @override
  Widget build(BuildContext context) {
    if (historicalMatches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'RAG MEMORY MATCH',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.blueAccent,
                ),
              ),
              Icon(Icons.history, color: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Found ${historicalMatches.length} similar past incidents',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...historicalMatches.map((match) => _buildMatchCard(match)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final score = (match['similarity_score'] as double) * 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match['date'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${score.toStringAsFixed(0)}% Match',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            match['summary'],
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text('Effective Playbook:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
          Text(
            match['response_playbook'],
            style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
