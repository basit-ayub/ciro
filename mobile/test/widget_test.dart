import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ciro_mobile/widgets/live_reasoning_stadium.dart';
import 'package:ciro_mobile/widgets/twin_timeline.dart';

void main() {
  testWidgets('LiveReasoningStadium renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveReasoningStadium(),
        ),
      ),
    );

    // Verify that the stadium header exists
    expect(find.text('LIVE REASONING STADIUM'), findsOneWidget);
    
    // Verify that the 3 agents are displayed
    expect(find.text('SENTINEL'), findsOneWidget);
    expect(find.text('ANALYST'), findsOneWidget);
    expect(find.text('COMMANDER'), findsOneWidget);
  });

  testWidgets('TwinTimelineWidget renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TwinTimelineWidget(),
        ),
      ),
    );

    // Verify header exists
    expect(find.text('COUNTERFACTUAL SIMULATOR'), findsOneWidget);
    
    // Verify timeline columns exist
    expect(find.text('WITHOUT CIRO'), findsOneWidget);
    expect(find.text('WITH CIRO'), findsOneWidget);
  });
}
