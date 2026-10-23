import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _publicPath = '/storage/v1/object/public/avatars/';
const _authenticatedPath = '/storage/v1/object/authenticated/avatars/';

/// The photo at [url]. Uploaded photos are in the private avatars bucket and
/// load with the signed-in user's token, so only their owner can open them;
/// any other photo (Google's) loads as it is.
ImageProvider avatarImage(String url) {
  final authenticated = authenticatedAvatarUrl(url);
  if (authenticated == null) return NetworkImage(url);
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  return NetworkImage(
    authenticated,
    headers: {
      'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      'Authorization': ?(token == null ? null : 'Bearer $token'),
    },
  );
}

/// [url] as the signed-in download link to the same avatars file, or null
/// for a photo stored elsewhere. Accounts from before the bucket was private
/// saved the public link.
String? authenticatedAvatarUrl(String url) {
  if (url.contains(_authenticatedPath)) return url;
  if (url.contains(_publicPath)) {
    return url.replaceFirst(_publicPath, _authenticatedPath);
  }
  return null;
}
