import '../../l10n/app_localizations.dart';
import 'Failure.dart';

/// Turns a failure message from a cubit into something safe to show users.
///
/// Repository messages are English and sometimes technical (exception text,
/// status codes), and they're already logged where they happen, so the UI
/// only distinguishes "no connection" from everything else.
String userFacingError(AppLocalizations l10n, String? message) {
  if (message == NetworkFailure.noConnectionMessage) return l10n.errorNoInternet;
  return l10n.errorGeneric;
}
