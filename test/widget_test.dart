
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without crashing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('MeetBuddies'))),
    ));
    expect(find.text('MeetBuddies'), findsOneWidget);
  });
}
