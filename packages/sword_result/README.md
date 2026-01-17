# SwordResult

Result type and helpers for error handling in Dart and Flutter.

## Usage

```dart
import 'package:sword_result/sword_result.dart';

final Result<int, String> value = Result.ok(42);
```

```dart
final Result<int, String> parsed = Result.tryCatch(
  () => int.parse('123'),
  (error, stackTrace) => 'parse_failed',
);
```
