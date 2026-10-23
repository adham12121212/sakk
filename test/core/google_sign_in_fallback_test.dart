import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sakk/core/service/supabase_client_impl.dart';

GoogleSignInException _error(GoogleSignInExceptionCode code, [String? text]) =>
    GoogleSignInException(code: code, description: text);

void main() {
  bool fallback(GoogleSignInException e) =>
      SupabaseServiceImpl.isGoogleSetupProblem(e);

  test("Google refusing the app's signing key opens the browser sign-in", () {
    // What Android reports when the SHA-1 isn't registered with Google.
    expect(
      fallback(
        _error(
          GoogleSignInExceptionCode.canceled,
          '[16] Account reauth failed.',
        ),
      ),
      isTrue,
    );
    expect(
      fallback(_error(GoogleSignInExceptionCode.canceled, '[10] ')),
      isTrue,
    );
    expect(
      fallback(_error(GoogleSignInExceptionCode.clientConfigurationError)),
      isTrue,
    );
    expect(
      fallback(_error(GoogleSignInExceptionCode.providerConfigurationError)),
      isTrue,
    );
  });

  test('a real cancel, or a passing problem, does not', () {
    expect(
      fallback(
        _error(
          GoogleSignInExceptionCode.canceled,
          'activity is cancelled by the user.',
        ),
      ),
      isFalse,
    );
    expect(fallback(_error(GoogleSignInExceptionCode.canceled)), isFalse);
    expect(fallback(_error(GoogleSignInExceptionCode.interrupted)), isFalse);
    expect(fallback(_error(GoogleSignInExceptionCode.uiUnavailable)), isFalse);
  });

  test('the return link matches the Android intent filter', () {
    final uri = Uri.parse(SupabaseServiceImpl.googleRedirectUrl);
    expect(uri.scheme, 'com.sakk.app');
    expect(uri.host, 'login-callback');
  });
}
