import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/providers/session_controls_provider.dart';

void main() {
  test('captureEnabledProvider starts enabled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(captureEnabledProvider), isTrue);
  });

  test('captureEnabledProvider can be disabled (pause)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(captureEnabledProvider.notifier).state = false;

    expect(container.read(captureEnabledProvider), isFalse);
  });

  test('captureEnabledProvider can be re-enabled after pause (resume)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(captureEnabledProvider.notifier).state = false;
    container.read(captureEnabledProvider.notifier).state = true;

    expect(container.read(captureEnabledProvider), isTrue);
  });

  test('state changes are isolated between containers', () {
    final container1 = ProviderContainer();
    final container2 = ProviderContainer();
    addTearDown(container1.dispose);
    addTearDown(container2.dispose);

    container1.read(captureEnabledProvider.notifier).state = false;

    expect(container1.read(captureEnabledProvider), isFalse);
    expect(container2.read(captureEnabledProvider), isTrue);
  });

  test('toggling multiple times ends in the correct final state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // pause → resume → pause
    container.read(captureEnabledProvider.notifier).state = false;
    container.read(captureEnabledProvider.notifier).state = true;
    container.read(captureEnabledProvider.notifier).state = false;

    expect(container.read(captureEnabledProvider), isFalse);
  });
}
