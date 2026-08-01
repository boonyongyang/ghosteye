import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/app_status.dart';

void main() {
  group('AppStatus.icon', () {
    test('maps each status to a distinct icon', () {
      final icons = AppStatus.values.map((status) => status.icon).toSet();
      expect(icons.length, equals(AppStatus.values.length));
    });

    test('uses the expected icons for key states', () {
      expect(AppStatus.ready.icon, Icons.check_circle_outline);
      expect(AppStatus.failed.icon, Icons.error_outline);
      expect(AppStatus.degraded.icon, Icons.warning_amber_outlined);
    });
  });

  group('AppStatus.color', () {
    testWidgets('resolves constant and theme-derived colours', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final scheme = Theme.of(ctx).colorScheme;

      expect(AppStatus.ready.color(ctx), const Color(0xFF4DD08A));
      expect(AppStatus.degraded.color(ctx), const Color(0xFFF2B95C));
      expect(AppStatus.needsAction.color(ctx), const Color(0xFFF2B95C));
      expect(AppStatus.working.color(ctx), scheme.primary);
      expect(AppStatus.failed.color(ctx), scheme.error);
    });
  });
}
