import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/util/avatar_image.dart';

void main() {
  const base = 'https://x.supabase.co/storage/v1/object';

  test('a saved public avatar link is read through the signed-in endpoint', () {
    expect(
      authenticatedAvatarUrl('$base/public/avatars/u1/avatar.jpg?updated=1'),
      '$base/authenticated/avatars/u1/avatar.jpg?updated=1',
    );
    expect(
      authenticatedAvatarUrl('$base/authenticated/avatars/u1/avatar.jpg'),
      '$base/authenticated/avatars/u1/avatar.jpg',
    );
  });

  test("photos stored elsewhere (Google's) load as they are", () {
    expect(
      authenticatedAvatarUrl('https://lh3.googleusercontent.com/a/x=s400'),
      isNull,
    );
    expect(authenticatedAvatarUrl('$base/public/logos/netflix.png'), isNull);
  });
}
