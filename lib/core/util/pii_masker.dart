class PiiMasker {
  PiiMasker._();

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return '***';
    final name = parts[0];
    final masked = name.length <= 2 ? '**' : '${name[0]}***${name[name.length - 1]}';
    return '$masked@${parts[1]}';
  }
  // Also matches already-masked addresses like `a***b@gmail.com`.
  static final _emailPattern = RegExp(r'''[^\s@'"<>(),;:]+@[^\s@'"<>(),;:]+\.[A-Za-z]{2,}''');

  /// Replaces every email-like substring with `[email]`. Used before anything
  /// leaves the device (e.g. Crashlytics), where even masked emails aren't allowed.
  static String scrubEmails(String text) => text.replaceAll(_emailPattern, '[email]');

  // Signed storage links (`?token=...`) and bare JWTs open private files or
  // act as credentials, so they never leave the device either.
  static final _tokenParam = RegExp(r'([?&]token=)[^&\s"]+');
  static final _jwt = RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+');

  /// Everything that must be removed before text leaves the device: emails,
  /// signed-link tokens and JWTs.
  static String scrub(String text) => scrubEmails(text)
      .replaceAllMapped(_tokenParam, (m) => '${m[1]}[token]')
      .replaceAll(_jwt, '[token]');

  // A full card number: 13 to 19 digits, optionally grouped by spaces or dashes.
  static final _cardNumber = RegExp(r'\b\d(?:[ -]?\d){12,18}\b');

  /// Shortens full card numbers to their last 4 digits (`•• 4242`). Amounts,
  /// dates, phone numbers and already-masked cards are left alone.
  static String maskCardNumbers(String text) => text.replaceAllMapped(_cardNumber, (m) {
        final digits = m[0]!.replaceAll(RegExp(r'\D'), '');
        return '•• ${digits.substring(digits.length - 4)}';
      });
}
