import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../features/products/domain/enties/product_entity.dart';
import '../../l10n/app_localizations.dart';
import '../locale_controller/locale_controller.dart';
import '../logger/app_logger.dart';

/// Keeps the home-screen widget showing the next warranty to end.
///
/// The widget only draws the texts saved here, in the app's language (which
/// can differ from the phone's). It shows the end date rather than "days
/// left", so it stays correct even if the app isn't opened for a while.
class HomeWidgetSync {
  HomeWidgetSync(this._localeController, this._logger);

  final LocaleController _localeController;
  final AppLogger _logger;

  /// Must match the Android provider class and the iOS widget `kind`.
  static const androidName = 'WarrantyWidgetProvider';
  static const iOSName = 'SakkWarrantyWidget';

  /// Shared container the iOS widget extension reads from.
  static const iOSAppGroup = 'group.com.sakk.app';

  Future<void> update(List<ProductEntity> products) async {
    final locale = _localeController.value;
    final l10n = lookupAppLocalizations(locale);
    final upcoming = products.where((p) => !p.isExpired).toList()
      ..sort((a, b) => a.warrantyEndDate.compareTo(b.warrantyEndDate));

    if (upcoming.isEmpty) {
      await _save(header: l10n.widgetNextToEnd, title: l10n.widgetNoWarranties, subtitle: '');
      return;
    }
    final next = upcoming.first;
    final dateLocale = locale.languageCode == 'ar' ? 'ar_EG' : locale.toLanguageTag();
    await _save(
      header: l10n.widgetNextToEnd,
      title: next.name,
      subtitle: l10n.widgetEndsOn(DateFormat.yMMMd(dateLocale).format(next.warrantyEndDate)),
    );
  }

  /// Re-renders the widget texts when the app language changes.
  void followLanguage(List<ProductEntity> Function() currentProducts) {
    _localeController.addListener(() {
      final products = currentProducts();
      if (products.isNotEmpty) update(products);
    });
  }

  /// On sign-out: never leave the last account's product on the home screen.
  Future<void> clear() async {
    final l10n = lookupAppLocalizations(_localeController.value);
    await _save(header: l10n.appName, title: l10n.widgetSignedOut, subtitle: '');
  }

  Future<void> _save({required String header, required String title, required String subtitle}) async {
    try {
      await HomeWidget.setAppGroupId(iOSAppGroup);
      await HomeWidget.saveWidgetData<String>('header', header);
      await HomeWidget.saveWidgetData<String>('title', title);
      await HomeWidget.saveWidgetData<String>('subtitle', subtitle);
      await HomeWidget.updateWidget(androidName: androidName, iOSName: iOSName);
    } catch (e) {
      // No widget placed yet, or the iOS extension isn't installed: harmless.
      _logger.warning('Updating the home screen widget failed', data: {'error': '$e'});
    }
  }
}
