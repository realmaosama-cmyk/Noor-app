import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/widgets/noor_arabic_keyboard.dart';

void main() {
  testWidgets('Arabic keyboard inserts and deletes child-name characters',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoorArabicKeyboard(controller: controller),
        ),
      ),
    );

    await tester.tap(find.text('م').first);
    await tester.pump();
    expect(controller.text, 'م');

    await tester.tap(find.text('س').first);
    await tester.pump();
    expect(controller.text, 'مس');

    await tester.tap(find.text('حذف'));
    await tester.pump();
    expect(controller.text, 'م');

    await tester.tap(find.text('مسح'));
    await tester.pump();
    expect(controller.text, isEmpty);

    controller.dispose();
  });
}
