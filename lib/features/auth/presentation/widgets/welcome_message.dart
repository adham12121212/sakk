import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_entity.dart';

/// What to greet [user] with after signing in or up: Google sign-in works on
/// both screens, so the account's age decides, not which screen it was.
String welcomeMessage(AppLocalizations l10n, UserEntity user) =>
    user.isNewAccount ? l10n.welcometoSakk : l10n.welcomeback;
