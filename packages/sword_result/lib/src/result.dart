/// Exception thrown when unwrap() is called on an Err value.
class UnwrapException extends StateError {
  final Object? error;

  UnwrapException(String message, [this.error]) : super(message);

  @override
  String toString() =>
      'UnwrapException: $message${error != null ? ' ($error)' : ''}';
}

/// Represents an unhandled exception captured by trySync/tryAsync.
class UnhandledException {
  final Object exception;
  final StackTrace? stackTrace;

  const UnhandledException(this.exception, [this.stackTrace]);

  @override
  String toString() => 'UnhandledException: $exception';
}

/// Exception used internally by Result.run for early return.
/// This is thrown by bind() when encountering an Err and caught by run().
class _EarlyReturn<E> implements Exception {
  final E error;
  const _EarlyReturn(this.error);
}

/// A typed result for error handling that avoids exceptions in flow control.
sealed class Result<T, E> {
  const Result();

  /// Creates an Ok result.
  const factory Result.ok(T value) = Ok<T, E>;

  /// Creates an Err result.
  const factory Result.err(E error) = Err<T, E>;

  /// Executes a synchronous function and wraps the result.
  /// If the function throws, returns Err with UnhandledException.
  static Result<T, UnhandledException> trySync<T>(T Function() body) {
    try {
      return Ok<T, UnhandledException>(body());
    } catch (error, stackTrace) {
      return Err<T, UnhandledException>(
        UnhandledException(error, stackTrace),
      );
    }
  }

  /// Executes a synchronous function with custom error handling.
  static Result<T, E> trySyncCatch<T, E>(
    T Function() body,
    E Function(Object error, StackTrace stackTrace) onError,
  ) {
    return tryCatch(body, onError);
  }

  /// Executes an asynchronous function and wraps the result.
  /// If the function throws, returns Err with UnhandledException.
  static Future<Result<T, UnhandledException>> tryAsync<T>(
    Future<T> Function() body,
  ) async {
    try {
      return Ok<T, UnhandledException>(await body());
    } catch (error, stackTrace) {
      return Err<T, UnhandledException>(
        UnhandledException(error, stackTrace),
      );
    }
  }

  /// Executes an asynchronous function with custom error handling.
  static Future<Result<T, E>> tryAsyncCatch<T, E>(
    Future<T> Function() body,
    E Function(Object error, StackTrace stackTrace) onError,
  ) async {
    try {
      return Ok<T, E>(await body());
    } catch (error, stackTrace) {
      return Err<T, E>(onError(error, stackTrace));
    }
  }

  /// Runs a function that uses bind() for early return on Err.
  static Result<T, E> run<T, E>(
    Result<T, E> Function(U Function<U>(Result<U, E> result) bind) fn,
  ) {
    try {
      return fn(<U>(Result<U, E> result) {
        switch (result) {
          case Ok(:final value):
            return value;
          case Err(:final error):
            throw _EarlyReturn<E>(error);
        }
      });
    } on _EarlyReturn<E> catch (e) {
      return Err<T, E>(e.error);
    }
  }

  /// Async version of run() for async operations.
  static Future<Result<T, E>> runAsync<T, E>(
    Future<Result<T, E>> Function(U Function<U>(Result<U, E> result) bind) fn,
  ) async {
    try {
      return await fn(<U>(Result<U, E> result) {
        switch (result) {
          case Ok(:final value):
            return value;
          case Err(:final error):
            throw _EarlyReturn<E>(error);
        }
      });
    } on _EarlyReturn<E> catch (e) {
      return Err<T, E>(e.error);
    }
  }

  /// Returns true when this result is Ok.
  bool get isOk => this is Ok<T, E>;

  /// Returns true when this result is Err.
  bool get isErr => this is Err<T, E>;

  /// Returns the Ok value or null when Err.
  T? get okOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  /// Returns the Err value or null when Ok.
  E? get errOrNull => switch (this) {
        Err(:final error) => error,
        Ok() => null,
      };

  /// Converts this result into a value using the provided callbacks.
  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };

  /// Pattern match on the result.
  R match<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) => fold(ok, err);

  /// Maps an Ok value, leaving Err untouched.
  Result<U, E> map<U>(U Function(T value) op) => switch (this) {
        Ok(:final value) => Ok<U, E>(op(value)),
        Err(:final error) => Err<U, E>(error),
      };

  /// Maps an Err value, leaving Ok untouched.
  Result<T, F> mapErr<F>(F Function(E error) op) => switch (this) {
        Ok(:final value) => Ok<T, F>(value),
        Err(:final error) => Err<T, F>(op(error)),
      };

  /// Maps an Err value, leaving Ok untouched.
  Result<T, F> mapError<F>(F Function(E error) op) => mapErr(op);

  /// Chains another Result-producing operation.
  Result<U, E> andThen<U>(Result<U, E> Function(T value) op) =>
      switch (this) {
        Ok(:final value) => op(value),
        Err(:final error) => Err<U, E>(error),
      };

  /// Chains another async Result-producing operation.
  Future<Result<U, E>> andThenAsync<U>(
    Future<Result<U, E>> Function(T value) op,
  ) =>
      switch (this) {
        Ok(:final value) => op(value),
        Err(:final error) => Future.value(Err<U, E>(error)),
      };

  /// Recovers from an Err with another Result.
  Result<T, E> orElse(Result<T, E> Function(E error) op) =>
      switch (this) {
        Ok(:final value) => Ok<T, E>(value),
        Err(:final error) => op(error),
      };

  /// Returns the Ok value or the provided fallback.
  T unwrapOr(T fallback) => switch (this) {
        Ok(:final value) => value,
        Err() => fallback,
      };

  /// Returns the Ok value or computes a fallback from Err.
  T unwrapOrElse(T Function(E error) op) => switch (this) {
        Ok(:final value) => value,
        Err(:final error) => op(error),
      };

  /// Returns the Ok value or throws an UnwrapException.
  T unwrap([String? message]) => switch (this) {
        Ok(:final value) => value,
        Err(:final error) => throw UnwrapException(
            message ?? 'Tried to unwrap Err', error),
      };

  /// Returns the Err value or throws an UnwrapException.
  E unwrapErr([String? message]) => switch (this) {
        Err(:final error) => error,
        Ok(:final value) => throw UnwrapException(
            message ?? 'Tried to unwrapErr Ok', value),
      };

  /// Returns the Ok value or throws an UnwrapException with a custom message.
  T expect(String message) => unwrap(message);

  /// Returns the Err value or throws an UnwrapException with a custom message.
  E expectErr(String message) => unwrapErr(message);

  /// Returns a record (T?, E?) for safe extraction without exceptions.
  /// Similar to Go's (value, error) pattern.
  (T?, E?) guard() => switch (this) {
        Ok(:final value) => (value, null),
        Err(:final error) => (null, error),
      };

  /// Runs a side-effect on Ok and returns the original result.
  Result<T, E> inspect(void Function(T value) op) {
    switch (this) {
      case Ok(:final value):
        op(value);
        return this;
      case Err():
        return this;
    }
  }

  /// Runs a side-effect on Err and returns the original result.
  Result<T, E> inspectErr(void Function(E error) op) {
    switch (this) {
      case Err(:final error):
        op(error);
        return this;
      case Ok():
        return this;
    }
  }

  /// Executes a function if this is Ok, returns the same Result.
  Result<T, E> tap(void Function(T value) op) => inspect(op);

  /// Executes an async function if this is Ok, returns the same Result.
  Future<Result<T, E>> tapAsync(Future<void> Function(T value) op) async {
    switch (this) {
      case Ok(:final value):
        await op(value);
        return this;
      case Err():
        return this;
    }
  }

  /// Creates a Result from a nullable value.
  static Result<T, E> fromNullable<T, E>(T? value, E error) {
    if (value == null) {
      return Err<T, E>(error);
    }
    return Ok<T, E>(value);
  }

  /// Creates a Result based on a predicate evaluation.
  static Result<T, E> fromPredicate<T, E>(
    T value,
    bool Function(T value) predicate,
    E Function(T value) error,
  ) {
    if (predicate(value)) {
      return Ok<T, E>(value);
    }
    return Err<T, E>(error(value));
  }

  /// Converts thrown errors into an Err.
  static Result<T, E> tryCatch<T, E>(
    T Function() body,
    E Function(Object error, StackTrace stackTrace) onError,
  ) {
    try {
      return Ok<T, E>(body());
    } catch (error, stackTrace) {
      return Err<T, E>(onError(error, stackTrace));
    }
  }
}

/// Represents a successful result.
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Represents a failed result.
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;

  @override
  bool operator ==(Object other) => other is Err<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash(Err, error);

  @override
  String toString() => 'Err($error)';
}
