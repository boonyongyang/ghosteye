import 'dart:async';

/// Small FIFO gate for serializing stateful async operations.
///
/// The gate deliberately does not retain errors from an operation. A failed
/// operation releases the next waiter, so one failed model install cannot
/// permanently wedge the runtime.
class AsyncMutex {
  Future<void> _tail = Future<void>.value();

  Future<T> protect<T>(Future<T> Function() action) async {
    final release = await acquire();
    try {
      return await action();
    } finally {
      release();
    }
  }

  Future<void Function()> acquire() async {
    final previous = _tail;
    final releaseCompleter = Completer<void>();
    _tail = releaseCompleter.future;
    await previous;

    var released = false;
    return () {
      if (released) {
        return;
      }
      released = true;
      releaseCompleter.complete();
    };
  }
}
