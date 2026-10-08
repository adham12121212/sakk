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
  /// leaves the device (e.g. Sentry), where even masked emails aren't allowed.
  static String scrubEmails(String text) => text.replaceAll(_emailPattern, '[email]');
}