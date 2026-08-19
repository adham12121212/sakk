class PiiMasker {
  PiiMasker._();

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return '***';
    final name = parts[0];
    final masked = name.length <= 2 ? '**' : '${name[0]}***${name[name.length - 1]}';
    return '$masked@${parts[1]}';
  }
}