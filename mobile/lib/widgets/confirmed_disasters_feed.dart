import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ciro_mobile/widgets/confirmed_disasters_provider.dart';


class ConfirmedDisastersFeed extends ConsumerWidget {
  const ConfirmedDisastersFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disasters = ref.watch(confirmedDisastersProvider);
    final activeId = ref.watch(activeDisasterIdProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, disasters.length),
          const Divider(height: 1, color: Colors.white10),
          if (disasters.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: disasters.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final disaster = disasters[index];
                final isActive = activeId == disaster.id;
                return _buildDisasterCard(ref, disaster, isActive);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'CONFIRMED ACTIVE DISASTERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0 ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: count > 0 ? Colors.redAccent.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.3),
              ),
            ),
            child: Text(
              count > 0 ? '$count ALERT${count > 1 ? 'S' : ''}' : 'NORMAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: count > 0 ? Colors.redAccent : Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
      child: Column(
        children: const [
          Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 36),
          SizedBox(height: 12),
          Text(
            'No Confirmed Disasters Active',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'AI Sentinel actively monitoring incoming Twilio, Weather, social, and Vision data streams.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterCard(WidgetRef ref, ConfirmedDisaster disaster, bool isActive) {
    final severityColor = disaster.severity >= 5
        ? Colors.red
        : disaster.severity >= 4
            ? Colors.orangeAccent
            : Colors.yellowAccent;

    return InkWell(
      onTap: () {
        ref.read(activeDisasterIdProvider.notifier).state = disaster.id;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF222222) : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.08),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    disaster.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: severityColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    'SEV ${disaster.severity}',
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    disaster.location,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
                Text(
                  'Confidence: ${disaster.confidenceScore.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    disaster.type,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      disaster.status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.alt_route, size: 12, color: Colors.greenAccent),
                        SizedBox(width: 6),
                        Text(
                          'DYNAMIC ROUTING MAP ACTIVE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detours calculated bypassing: ${disaster.blockedRouteDescription}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
