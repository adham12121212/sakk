import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Face ID / Touch ID'**
  String get signInWithBiometrics;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sakk'**
  String get appName;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinSakkToday.
  ///
  /// In en, this message translates to:
  /// **'Join Sakk today'**
  String get joinSakkToday;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Al-Omari'**
  String get fullNameHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+020 5x xxx xxxx'**
  String get phoneHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @agreeToTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTermsPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Service and Privacy Policy'**
  String get pleaseAgreeToTerms;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @warrantyMonths.
  ///
  /// In en, this message translates to:
  /// **'Warranty (months)'**
  String get warrantyMonths;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDate;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product Image'**
  String get productImage;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get productNameRequired;

  /// No description provided for @warrantyRequired.
  ///
  /// In en, this message translates to:
  /// **'Warranty length is required'**
  String get warrantyRequired;

  /// No description provided for @priceEgp.
  ///
  /// In en, this message translates to:
  /// **'Price(EGP)'**
  String get priceEgp;

  /// No description provided for @productSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product saved successfully'**
  String get productSavedSuccessfully;

  /// No description provided for @invalidWarrantyMonths.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number of months'**
  String get invalidWarrantyMonths;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @totalSpant.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpant;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @proUser.
  ///
  /// In en, this message translates to:
  /// **'Pro User'**
  String get proUser;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your products.'**
  String get logOutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @warrantyStatus.
  ///
  /// In en, this message translates to:
  /// **'Warranty Status'**
  String get warrantyStatus;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @expiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiring;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @welcomeback.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeback;

  /// No description provided for @welcometoSakk.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sakk!'**
  String get welcometoSakk;

  /// No description provided for @atleast8characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atleast8characters;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'product'**
  String get product;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @appliances.
  ///
  /// In en, this message translates to:
  /// **'Appliances'**
  String get appliances;

  /// No description provided for @furniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get furniture;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @accessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get accessories;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @aIAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aIAssistant;

  /// No description provided for @howdoIaddanewproduct.
  ///
  /// In en, this message translates to:
  /// **'How do I add a new product?'**
  String get howdoIaddanewproduct;

  /// No description provided for @whatshouldIdoifaproductbreaks.
  ///
  /// In en, this message translates to:
  /// **'What should I do if a product breaks?'**
  String get whatshouldIdoifaproductbreaks;

  /// No description provided for @askmeanything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything'**
  String get askmeanything;

  /// No description provided for @icanhelpwithyourproductswarrantiesandpurchases.
  ///
  /// In en, this message translates to:
  /// **'I can help with your products, warranties, and purchases.'**
  String get icanhelpwithyourproductswarrantiesandpurchases;

  /// No description provided for @askaboutaproductorwarranty.
  ///
  /// In en, this message translates to:
  /// **'Ask about a product or warranty…'**
  String get askaboutaproductorwarranty;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get productUpdated;

  /// No description provided for @deleteProductQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get deleteProductQuestion;

  /// No description provided for @deleteProductConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{productName}\" will be permanently removed. This can\'t be undone.'**
  String deleteProductConfirmBody(Object productName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get downloadInvoice;

  /// No description provided for @noInvoiceAvailable.
  ///
  /// In en, this message translates to:
  /// **'No invoice available'**
  String get noInvoiceAvailable;

  /// No description provided for @couldNotOpenShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet: {error}'**
  String couldNotOpenShareSheet(Object error);

  /// No description provided for @noInvoiceImageToDownload.
  ///
  /// In en, this message translates to:
  /// **'No invoice image to download for this product.'**
  String get noInvoiceImageToDownload;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(Object error);

  /// No description provided for @couldNotDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete this product. Please try again.'**
  String get couldNotDeleteProduct;

  /// No description provided for @warrantyPeriod.
  ///
  /// In en, this message translates to:
  /// **'Warranty Period'**
  String get warrantyPeriod;

  /// No description provided for @detailsTab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTab;

  /// No description provided for @invoiceTab.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceTab;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day left} other{{days} days left}}'**
  String daysLeft(int days);

  /// No description provided for @warrantyExpired.
  ///
  /// In en, this message translates to:
  /// **'Warranty expired'**
  String get warrantyExpired;

  /// No description provided for @expiresOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires on: {date}'**
  String expiresOnLabel(Object date);

  /// No description provided for @shareBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand: {brand}'**
  String shareBrand(Object brand);

  /// No description provided for @shareStore.
  ///
  /// In en, this message translates to:
  /// **'Store: {store}'**
  String shareStore(Object store);

  /// No description provided for @sharePrice.
  ///
  /// In en, this message translates to:
  /// **'Price: {currency} {price}'**
  String sharePrice(Object currency, Object price);

  /// No description provided for @sharePurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased: {date}'**
  String sharePurchased(Object date);

  /// No description provided for @shareWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty: {months} months'**
  String shareWarranty(Object months);

  /// No description provided for @shareExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String shareExpires(Object date);

  /// No description provided for @shareInvoiceUrl.
  ///
  /// In en, this message translates to:
  /// **'\nInvoice: {url}'**
  String shareInvoiceUrl(Object url);

  /// No description provided for @invoiceShareText.
  ///
  /// In en, this message translates to:
  /// **'Invoice — {name}'**
  String invoiceShareText(Object name);

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @enteryouremailandwellsendyouacodetoresetyourpassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a code to reset your password.'**
  String get enteryouremailandwellsendyouacodetoresetyourpassword;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @passwordupdatedpleasesigninagain.
  ///
  /// In en, this message translates to:
  /// **'Password updated please sign in again'**
  String get passwordupdatedpleasesigninagain;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCode;

  /// No description provided for @weSentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a {length}-digit code to {email}'**
  String weSentCodeTo(Object email, Object length);

  /// No description provided for @newCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'A new code was sent to your email'**
  String get newCodeSentToEmail;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @enterDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the {length}-digit code'**
  String enterDigitCode(Object length);

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @chooseNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get chooseNewPasswordSubtitle;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordButton;

  /// No description provided for @recentProducts.
  ///
  /// In en, this message translates to:
  /// **'Recent Products'**
  String get recentProducts;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @activeWarranties.
  ///
  /// In en, this message translates to:
  /// **'Active Warranties'**
  String get activeWarranties;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// No description provided for @warrantiesExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 warranty is expiring soon} other{{count} warranties are expiring soon}}'**
  String warrantiesExpiringSoon(int count);

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night,'**
  String get goodNight;

  /// No description provided for @guestFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get guestFallbackName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @nonotificationsyet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get nonotificationsyet;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @onboardingScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Your Receipts'**
  String get onboardingScanTitle;

  /// No description provided for @onboardingScanDescription.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo of any receipt or warranty card and let AI pull out the details automatically.'**
  String get onboardingScanDescription;

  /// No description provided for @onboardingTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Every Warranty'**
  String get onboardingTrackTitle;

  /// No description provided for @onboardingTrackDescription.
  ///
  /// In en, this message translates to:
  /// **'See at a glance which products are active, expiring soon, or already expired.'**
  String get onboardingTrackDescription;

  /// No description provided for @onboardingNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Never Miss a Deadline'**
  String get onboardingNotifyTitle;

  /// No description provided for @onboardingNotifyDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified before a warranty runs out, so you never lose coverage you\'re entitled to.'**
  String get onboardingNotifyDescription;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Sakk — AI Warranty Manager'**
  String get appTagline;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @nothingInThisFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this filter'**
  String get nothingInThisFilter;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProductsHint;

  /// No description provided for @noProductsMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No products match \"{query}\"'**
  String noProductsMatchQuery(Object query);

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @couldNotReadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that receipt'**
  String get couldNotReadReceipt;

  /// No description provided for @tryAnotherPhoto.
  ///
  /// In en, this message translates to:
  /// **'Try Another Photo'**
  String get tryAnotherPhoto;

  /// No description provided for @aiIsProcessing.
  ///
  /// In en, this message translates to:
  /// **'AI is Processing'**
  String get aiIsProcessing;

  /// No description provided for @extractionComplete.
  ///
  /// In en, this message translates to:
  /// **'Extraction Complete'**
  String get extractionComplete;

  /// No description provided for @extractingData.
  ///
  /// In en, this message translates to:
  /// **'Extracting Data...'**
  String get extractingData;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @scanReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceiptTitle;

  /// No description provided for @scanYourWarrantyReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan your warranty receipt'**
  String get scanYourWarrantyReceipt;

  /// No description provided for @scanInstructions.
  ///
  /// In en, this message translates to:
  /// **'We\'ll pull out the product, price, and warranty info automatically.'**
  String get scanInstructions;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @confidenceScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence Score: '**
  String get confidenceScoreLabel;

  /// No description provided for @doubleCheckFieldsBelow.
  ///
  /// In en, this message translates to:
  /// **'Please double-check the fields below.'**
  String get doubleCheckFieldsBelow;

  /// No description provided for @lowConfidenceWarning.
  ///
  /// In en, this message translates to:
  /// **'We weren\'t fully confident reading this receipt — please double-check every field.'**
  String get lowConfidenceWarning;

  /// No description provided for @invoicePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Preview'**
  String get invoicePreviewLabel;

  /// No description provided for @warrantyDuration.
  ///
  /// In en, this message translates to:
  /// **'Warranty Duration'**
  String get warrantyDuration;

  /// No description provided for @warrantyMonthsValue.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String warrantyMonthsValue(Object months);

  /// No description provided for @verifyDetails.
  ///
  /// In en, this message translates to:
  /// **'Verify Details'**
  String get verifyDetails;

  /// No description provided for @reviewAndEditExtractedData.
  ///
  /// In en, this message translates to:
  /// **'Review and edit extracted data'**
  String get reviewAndEditExtractedData;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Login with Face ID / Fingerprint'**
  String get biometricLogin;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication isn\'t available on this device.'**
  String get biometricNotAvailable;

  /// No description provided for @biometricConfirmEnableReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to enable Face ID / Fingerprint login'**
  String get biometricConfirmEnableReason;

  /// No description provided for @biometricUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Sakk to continue'**
  String get biometricUnlockReason;

  /// No description provided for @appLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sakk is locked'**
  String get appLockedTitle;

  /// No description provided for @appLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or your fingerprint to continue.'**
  String get appLockedSubtitle;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use password instead'**
  String get usePasswordInstead;

  /// No description provided for @biometricRequiresActiveSession.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your password first to enable quick biometric access.'**
  String get biometricRequiresActiveSession;

  /// No description provided for @biometricNotEnabledYet.
  ///
  /// In en, this message translates to:
  /// **'Biometric login isn\'t enabled yet. Turn it on from Profile settings.'**
  String get biometricNotEnabledYet;

  /// No description provided for @scannedPriceValue.
  ///
  /// In en, this message translates to:
  /// **'{price} EGP'**
  String scannedPriceValue(Object price);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, all your products, receipts and notifications. This can\'t be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountKeyword.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountKeyword;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {keyword} to confirm'**
  String deleteAccountTypeToConfirm(String keyword);

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get accountDeleted;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @clearCategoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear category filter'**
  String get clearCategoryFilter;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{1 minute ago} other{{minutes} minutes ago}}'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{1 hour ago} other{{hours} hours ago}}'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day ago} other{{days} days ago}}'**
  String timeDaysAgo(int days);

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNoInternet;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @couldNotShare.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet. Please try again.'**
  String get couldNotShare;

  /// No description provided for @couldNotDownloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the invoice. Please try again.'**
  String get couldNotDownloadInvoice;

  /// Screen-reader text for the unread badge on the notifications bell. count picks the plural form; formattedCount is the same number in the locale's digits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{formattedCount} unread notification} other{{formattedCount} unread notifications}}'**
  String unreadNotificationsLabel(int count, String formattedCount);

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing saved data.'**
  String get offlineBanner;

  /// No description provided for @backOnlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get backOnlineBanner;

  /// No description provided for @errorOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get errorOfflineTitle;

  /// No description provided for @errorOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection, then try again.'**
  String get errorOfflineBody;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this right now. Please try again in a moment.'**
  String get errorGenericBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @messageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Tap to retry'**
  String get messageNotSent;

  /// No description provided for @enterDetailsManually.
  ///
  /// In en, this message translates to:
  /// **'Enter details manually'**
  String get enterDetailsManually;

  /// No description provided for @addProductManuallyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductManuallyTitle;

  /// No description provided for @addProductManuallySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in your product\'s details'**
  String get addProductManuallySubtitle;

  /// No description provided for @warrantyReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me before warranty ends'**
  String get warrantyReminder;

  /// No description provided for @reminder3Months.
  ///
  /// In en, this message translates to:
  /// **'3 mo'**
  String get reminder3Months;

  /// No description provided for @reminder1Month.
  ///
  /// In en, this message translates to:
  /// **'1 mo'**
  String get reminder1Month;

  /// No description provided for @reminder1Week.
  ///
  /// In en, this message translates to:
  /// **'1 wk'**
  String get reminder1Week;

  /// No description provided for @reminder1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get reminder1Day;

  /// No description provided for @warrantyEnds.
  ///
  /// In en, this message translates to:
  /// **'Warranty ends'**
  String get warrantyEnds;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @exportProducts.
  ///
  /// In en, this message translates to:
  /// **'Export products'**
  String get exportProducts;

  /// No description provided for @returnWindowDays.
  ///
  /// In en, this message translates to:
  /// **'Return window (days, optional)'**
  String get returnWindowDays;

  /// No description provided for @invalidReturnDays.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 365, or leave it empty'**
  String get invalidReturnDays;

  /// No description provided for @returnBy.
  ///
  /// In en, this message translates to:
  /// **'Return by'**
  String get returnBy;

  /// No description provided for @returnByValue.
  ///
  /// In en, this message translates to:
  /// **'{date} ({days, plural, =0{last day} one{1 day left} other{{days} days left}})'**
  String returnByValue(Object date, num days);

  /// No description provided for @returnWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed on {date}'**
  String returnWindowClosed(Object date);

  /// No description provided for @coveredUntil.
  ///
  /// In en, this message translates to:
  /// **'Covered until'**
  String get coveredUntil;

  /// No description provided for @extraWarranties.
  ///
  /// In en, this message translates to:
  /// **'Extra warranties'**
  String get extraWarranties;

  /// No description provided for @extraWarrantiesHint.
  ///
  /// In en, this message translates to:
  /// **'Bought an extended warranty? Add it so reminders use the right date.'**
  String get extraWarrantiesHint;

  /// No description provided for @addWarranty.
  ///
  /// In en, this message translates to:
  /// **'Add warranty'**
  String get addWarranty;

  /// No description provided for @warrantyProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get warrantyProvider;

  /// No description provided for @warrantyProviderHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. B.TECH extended warranty'**
  String get warrantyProviderHint;

  /// No description provided for @warrantyProviderRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter who gives this warranty'**
  String get warrantyProviderRequired;

  /// No description provided for @warrantyStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get warrantyStartDate;

  /// No description provided for @warrantyClaims.
  ///
  /// In en, this message translates to:
  /// **'Warranty claims'**
  String get warrantyClaims;

  /// No description provided for @warrantyClaimsHint.
  ///
  /// In en, this message translates to:
  /// **'Something broke? Start a claim to get a ready-to-send message and track its status.'**
  String get warrantyClaimsHint;

  /// No description provided for @startClaim.
  ///
  /// In en, this message translates to:
  /// **'Start a claim'**
  String get startClaim;

  /// No description provided for @startClaimExplanation.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem. We\'ll save the claim and prepare a message with the product and invoice details that you can send by WhatsApp or email.'**
  String get startClaimExplanation;

  /// No description provided for @claimIssue.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get claimIssue;

  /// No description provided for @claimIssueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. The screen stopped turning on'**
  String get claimIssueHint;

  /// No description provided for @claimIssueRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get claimIssueRequired;

  /// No description provided for @saveAndSendClaim.
  ///
  /// In en, this message translates to:
  /// **'Save and send'**
  String get saveAndSendClaim;

  /// No description provided for @claimSubject.
  ///
  /// In en, this message translates to:
  /// **'Warranty claim: {product}'**
  String claimSubject(Object product);

  /// No description provided for @claimMessageIntro.
  ///
  /// In en, this message translates to:
  /// **'Hello, I\'d like to make a warranty claim for my {product}, bought on {purchaseDate}. It is under warranty until {endDate}.'**
  String claimMessageIntro(Object endDate, Object product, Object purchaseDate);

  /// No description provided for @claimMessageIssue.
  ///
  /// In en, this message translates to:
  /// **'Problem: {issue}'**
  String claimMessageIssue(Object issue);

  /// No description provided for @claimStatus.
  ///
  /// In en, this message translates to:
  /// **'Claim status'**
  String get claimStatus;

  /// No description provided for @claimSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get claimSubmitted;

  /// No description provided for @claimInRepair.
  ///
  /// In en, this message translates to:
  /// **'In repair'**
  String get claimInRepair;

  /// No description provided for @claimResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get claimResolved;

  /// No description provided for @claimRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get claimRejected;

  /// No description provided for @deleteClaim.
  ///
  /// In en, this message translates to:
  /// **'Delete claim'**
  String get deleteClaim;

  /// No description provided for @widgetNextToEnd.
  ///
  /// In en, this message translates to:
  /// **'Next warranty to end'**
  String get widgetNextToEnd;

  /// No description provided for @widgetEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String widgetEndsOn(Object date);

  /// No description provided for @widgetNoWarranties.
  ///
  /// In en, this message translates to:
  /// **'No active warranties'**
  String get widgetNoWarranties;

  /// No description provided for @widgetSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Open Sakk to see your warranties'**
  String get widgetSignedOut;

  /// No description provided for @hideTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Hide total spent'**
  String get hideTotalSpent;

  /// No description provided for @showTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Show total spent'**
  String get showTotalSpent;

  /// No description provided for @totalSpentHidden.
  ///
  /// In en, this message translates to:
  /// **'Total spent hidden'**
  String get totalSpentHidden;

  /// No description provided for @invoiceSavedToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved to your photos'**
  String get invoiceSavedToPhotos;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get serialNumber;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get invoiceNumber;

  /// No description provided for @foreignPriceHint.
  ///
  /// In en, this message translates to:
  /// **'The receipt shows {amount}. Enter the price in EGP.'**
  String foreignPriceHint(Object amount);

  /// No description provided for @scanUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read that photo. Try a clearer, well-lit photo of the receipt, or enter the details manually.'**
  String get scanUnreadable;

  /// No description provided for @scanBusy.
  ///
  /// In en, this message translates to:
  /// **'Too many scans right now. Please try again in a minute.'**
  String get scanBusy;

  /// No description provided for @uploadPdfInvoice.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF Invoice'**
  String get uploadPdfInvoice;

  /// No description provided for @pdfUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open that PDF. If it\'s password-protected, remove the password and try again.'**
  String get pdfUnreadable;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Already added?'**
  String get duplicateTitle;

  /// No description provided for @duplicateSameInvoice.
  ///
  /// In en, this message translates to:
  /// **'You already have a product with this invoice number.'**
  String get duplicateSameInvoice;

  /// No description provided for @duplicateSameSerial.
  ///
  /// In en, this message translates to:
  /// **'You already have a product with this serial number.'**
  String get duplicateSameSerial;

  /// No description provided for @duplicateSameNameAndDate.
  ///
  /// In en, this message translates to:
  /// **'You already have this product, bought on the same day.'**
  String get duplicateSameNameAndDate;

  /// No description provided for @duplicateExisting.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}, bought {date}.'**
  String duplicateExisting(Object date, Object name);

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnyway;

  /// No description provided for @familySharing.
  ///
  /// In en, this message translates to:
  /// **'Family sharing'**
  String get familySharing;

  /// No description provided for @familySharingHint.
  ///
  /// In en, this message translates to:
  /// **'Create a household to share your products with your family, or join one with an invite code.'**
  String get familySharingHint;

  /// No description provided for @createHousehold.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createHousehold;

  /// No description provided for @joinHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinHousehold;

  /// No description provided for @householdName.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdName;

  /// No description provided for @householdNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. The Ahmeds'**
  String get householdNameHint;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @householdCreated.
  ///
  /// In en, this message translates to:
  /// **'Household created. Share the invite code with your family.'**
  String get householdCreated;

  /// No description provided for @householdJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined the household.'**
  String get householdJoined;

  /// No description provided for @householdSharedHint.
  ///
  /// In en, this message translates to:
  /// **'Members see each other\'s products. Only the person who added a product can edit it.'**
  String get householdSharedHint;

  /// No description provided for @copyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get copyInviteCode;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopied;

  /// No description provided for @shareInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Share invite code'**
  String get shareInviteCode;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join our household \"{name}\" in Sakk with this invite code: {code}'**
  String inviteMessage(Object code, Object name);

  /// No description provided for @newInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Make a new code'**
  String get newInviteCode;

  /// No description provided for @newInviteCodeCreated.
  ///
  /// In en, this message translates to:
  /// **'New invite code created. The old one no longer works.'**
  String get newInviteCodeCreated;

  /// No description provided for @householdMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get householdMembers;

  /// No description provided for @memberYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String memberYou(Object name);

  /// No description provided for @householdOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get householdOwner;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @removeMemberQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeMemberQuestion(Object name);

  /// No description provided for @removeMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer see the household\'s products, and you won\'t see theirs.'**
  String get removeMemberBody;

  /// No description provided for @leaveHousehold.
  ///
  /// In en, this message translates to:
  /// **'Leave household'**
  String get leaveHousehold;

  /// No description provided for @leaveHouseholdQuestion.
  ///
  /// In en, this message translates to:
  /// **'Leave the household?'**
  String get leaveHouseholdQuestion;

  /// No description provided for @leaveHouseholdBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop seeing the other members\' products, and they\'ll stop seeing yours.'**
  String get leaveHouseholdBody;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String addedBy(Object name);

  /// No description provided for @addedByHouseholdMember.
  ///
  /// In en, this message translates to:
  /// **'Added by a household member'**
  String get addedByHouseholdMember;

  /// No description provided for @invalidInviteCode.
  ///
  /// In en, this message translates to:
  /// **'That invite code doesn\'t match any household.'**
  String get invalidInviteCode;

  /// No description provided for @alreadyInHousehold.
  ///
  /// In en, this message translates to:
  /// **'You\'re already in a household. Leave it first to join another.'**
  String get alreadyInHousehold;

  /// No description provided for @householdFull.
  ///
  /// In en, this message translates to:
  /// **'This household already has 10 members.'**
  String get householdFull;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get addDocument;

  /// No description provided for @documentsHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the warranty card, a product photo or the manual here, next to the receipt.'**
  String get documentsHint;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents added.'**
  String get noDocuments;

  /// No description provided for @documentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get documentReceipt;

  /// No description provided for @documentWarrantyCard.
  ///
  /// In en, this message translates to:
  /// **'Warranty card'**
  String get documentWarrantyCard;

  /// No description provided for @documentProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get documentProductPhoto;

  /// No description provided for @documentManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get documentManual;

  /// No description provided for @documentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get documentOther;

  /// No description provided for @choosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF'**
  String get choosePdf;

  /// No description provided for @analyticsMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get analyticsMine;

  /// No description provided for @analyticsHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get analyticsHousehold;

  /// No description provided for @spendingByYear.
  ///
  /// In en, this message translates to:
  /// **'Spending by year'**
  String get spendingByYear;

  /// No description provided for @topStores.
  ///
  /// In en, this message translates to:
  /// **'Top stores'**
  String get topStores;

  /// No description provided for @addWarrantyEndToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add warranty end to calendar'**
  String get addWarrantyEndToCalendar;

  /// No description provided for @addReturnDeadlineToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add return deadline to calendar'**
  String get addReturnDeadlineToCalendar;

  /// No description provided for @calendarWarrantyEnds.
  ///
  /// In en, this message translates to:
  /// **'Warranty ends: {product}'**
  String calendarWarrantyEnds(Object product);

  /// No description provided for @calendarReturnDeadline.
  ///
  /// In en, this message translates to:
  /// **'Last day to return: {product}'**
  String calendarReturnDeadline(Object product);

  /// No description provided for @calendarEventDescription.
  ///
  /// In en, this message translates to:
  /// **'Added from Sakk for {product}.'**
  String calendarEventDescription(Object product);

  /// No description provided for @couldNotOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your calendar app.'**
  String get couldNotOpenCalendar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
