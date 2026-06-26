import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nootriscan/main.dart';
import 'package:nootriscan/providers/allergy_provider.dart';
import 'package:nootriscan/providers/analysis_provider.dart';

void main() {
  testWidgets('NootriScan app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AllergyProvider()),
          ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ],
        child: const MaterialApp(
          home: NootriScanApp(),
        ),
      ),
    );

    // Verify splash screen tampil
    expect(find.text('NootriScan'), findsOneWidget);
    expect(find.text('Analyze your meal with one click!'), findsOneWidget);
  });
}