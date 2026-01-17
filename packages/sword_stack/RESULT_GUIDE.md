# Result via sword_stack (AI Quick Guide)

Use this to keep error handling consistent across the codebase.

## Import

```dart
import 'package:sword_stack/sword_stack.dart';
```

## Always construct with Ok or Err

```dart
final Result<int, String> ok = Result.ok(42);
final Result<int, String> err = Result.err('invalid');
```

## Check with pattern matching

```dart
switch (result) {
  case Ok(value: final value):
    // use value
  case Err(error: final error):
    // handle error
}
```

## Extract value with late + early return

```dart
Result<Profile, ApiError> buildProfile() {
  final userResult = fetchUser();

  late final User user;
  switch (userResult) {
    case Ok(value: final value):
      user = value;
    case Err(error: final error):
      return Err(error);
  }

  return Ok(Profile.from(user));
}
```

## Block extraction with Result.run (early return on Err)

```dart
final result = Result.run<String, ApiError>((bind) {
  final user = bind(fetchUser());
  final posts = bind(fetchPosts(user.id));
  return Result.ok('${user.name} has ${posts.length} posts');
});

switch (result) {
  case Ok(value: final message):
    // use message
  case Err(error: final error):
    // handle error
}
```

## Async block

```dart
final result = await Result.runAsync<String, ApiError>((bind) async {
  final user = bind(await fetchUserAsync());
  final posts = bind(await fetchPostsAsync(user.id));
  return Result.ok('${user.name} has ${posts.length} posts');
});
```
