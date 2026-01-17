# SwordStack

Monorepo for the SwordStack Dart and Flutter libraries.

## Packages

- `packages/sword_result`: Result type and helpers for error handling.
- `packages/sword_stack`: Umbrella package that re-exports bundled libraries.

## Usage

```dart
import 'package:sword_result/sword_result.dart';

final Result<int, String> value = Result.ok(42);
```

```dart
import 'package:sword_stack/sword_stack.dart';

final Result<int, String> value = Result.ok(42);
```
