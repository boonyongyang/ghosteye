import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/services/async_mutex.dart';

void main() {
  test('AsyncMutex runs overlapping operations in arrival order', () async {
    final mutex = AsyncMutex();
    final events = <String>[];

    final first = mutex.protect(() async {
      events.add('first-start');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      events.add('first-end');
    });
    final second = mutex.protect(() async {
      events.add('second-start');
      events.add('second-end');
    });

    await Future.wait(<Future<void>>[first, second]);

    expect(events, <String>[
      'first-start',
      'first-end',
      'second-start',
      'second-end',
    ]);
  });
}
