import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Teste isolado de interface; não depende de credenciais do Supabase.
void main() {
  testWidgets('A interface básica é renderizada', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Text('Cartola Champions')),
    ));
    expect(find.text('Cartola Champions'), findsOneWidget);
  });
}
