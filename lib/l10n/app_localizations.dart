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
  /// **'example@gmail.com'**
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

  /// countText is the number in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 installment plan is linked to this product. It will be kept, without the link.} other{{countText} installment plans are linked to this product. They will be kept, without the link.}}'**
  String deleteProductLinkedPlans(int count, String countText);

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

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day left} other{{daysText} days left}}'**
  String daysLeft(int days, String daysText);

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

  /// No description provided for @resetCodeSentIfAccountExists.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, we\'ve sent it a {length}-digit code. Check your inbox and spam folder.'**
  String resetCodeSentIfAccountExists(String email, String length);

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(String seconds);

  /// No description provided for @resetRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Wait a minute, then try again.'**
  String get resetRateLimited;

  /// No description provided for @resetInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired. Check it or request a new one.'**
  String get resetInvalidCode;

  /// No description provided for @resetSamePassword.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from your old one.'**
  String get resetSamePassword;

  /// No description provided for @resetWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'This password is too common or has appeared in a data breach. Choose a different one.'**
  String get resetWeakPassword;

  /// No description provided for @resetGoogleAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Signed up with Google? Your account has no password. Go back and sign in with the Google button instead.'**
  String get resetGoogleAccountNote;

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

  /// countText is the number in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 warranty is expiring soon} other{{countText} warranties are expiring soon}}'**
  String warrantiesExpiringSoon(int count, String countText);

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
  /// **'Snap a photo of a receipt or warranty card, or upload a PDF invoice, and AI fills in the details for you.'**
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
  /// **'This permanently deletes your account and all its data: products, receipts and documents, subscriptions, installment plans, chat history and notifications. This can\'t be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountProTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sakk Pro first'**
  String get deleteAccountProTitle;

  /// No description provided for @deleteAccountProBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account doesn\'t cancel your Sakk Pro subscription in Google Play. Cancel it there first so you aren\'t charged again.'**
  String get deleteAccountProBody;

  /// No description provided for @deleteAccountProContinue.
  ///
  /// In en, this message translates to:
  /// **'Delete anyway'**
  String get deleteAccountProContinue;

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

  /// minutesText is the number in the app's digits; minutes picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{1 minute ago} other{{minutesText} minutes ago}}'**
  String timeMinutesAgo(int minutes, String minutesText);

  /// hoursText is the number in the app's digits; hours picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{1 hour ago} other{{hoursText} hours ago}}'**
  String timeHoursAgo(int hours, String hoursText);

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day ago} other{{daysText} days ago}}'**
  String timeDaysAgo(int days, String daysText);

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

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{date} ({days, plural, =0{last day} one{1 day left} other{{daysText} days left}})'**
  String returnByValue(String date, int days, String daysText);

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

  /// No description provided for @onboardingFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with Your Family'**
  String get onboardingFamilyTitle;

  /// No description provided for @onboardingFamilyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a household so everyone sees the family\'s warranties, and ask the AI assistant anything about your products.'**
  String get onboardingFamilyDescription;

  /// No description provided for @notifExpiringTitle.
  ///
  /// In en, this message translates to:
  /// **'Warranty expiring soon'**
  String get notifExpiringTitle;

  /// No description provided for @notifExpiringBody.
  ///
  /// In en, this message translates to:
  /// **'{product}\'s warranty is ending soon'**
  String notifExpiringBody(Object product);

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{product}\'s warranty ends in {days, plural, one{1 day} other{{daysText} days}}'**
  String notifExpiringInDays(int days, String daysText, String product);

  /// No description provided for @notifExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Warranty expired'**
  String get notifExpiredTitle;

  /// No description provided for @notifExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'{product}\'s warranty has expired'**
  String notifExpiredBody(Object product);

  /// No description provided for @notifReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'Return window closing'**
  String get notifReturnTitle;

  /// No description provided for @notifReturnBody.
  ///
  /// In en, this message translates to:
  /// **'You have 2 days left to return {product} if you need to'**
  String notifReturnBody(Object product);

  /// No description provided for @confirmEmailToFinishSignup.
  ///
  /// In en, this message translates to:
  /// **'Check your email and open the confirmation link, then sign in'**
  String get confirmEmailToFinishSignup;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @subscriptionsMonthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get subscriptionsMonthlyTotal;

  /// No description provided for @subscriptionsYearlyTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} a year'**
  String subscriptionsYearlyTotal(String amount);

  /// countText is the number in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No subscriptions} one{1 subscription} other{{countText} subscriptions}}'**
  String subscriptionsCount(int count, String countText);

  /// No description provided for @noSubscriptionsYet.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get noSubscriptionsYet;

  /// No description provided for @noSubscriptionsBody.
  ///
  /// In en, this message translates to:
  /// **'Add Netflix, Spotify and the rest to see what you pay each month and get reminded before each renewal.'**
  String get noSubscriptionsBody;

  /// No description provided for @subscriptionsHomeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Track Netflix, Spotify and more'**
  String get subscriptionsHomeEmpty;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscription;

  /// No description provided for @editSubscription.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get editSubscription;

  /// No description provided for @customSubscription.
  ///
  /// In en, this message translates to:
  /// **'Custom subscription'**
  String get customSubscription;

  /// No description provided for @customSubscriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Not in the list? Enter it yourself'**
  String get customSubscriptionHint;

  /// No description provided for @searchServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get searchServicesHint;

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services match your search'**
  String get noServicesFound;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get choosePlan;

  /// No description provided for @otherPlan.
  ///
  /// In en, this message translates to:
  /// **'Other plan'**
  String get otherPlan;

  /// No description provided for @otherPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the price yourself'**
  String get otherPlanHint;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {amount}'**
  String fromPrice(String amount);

  /// No description provided for @subscriptionName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subscriptionName;

  /// No description provided for @subscriptionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get subscriptionNameRequired;

  /// No description provided for @planNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Plan (optional)'**
  String get planNameOptional;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the price'**
  String get priceRequired;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @billingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing cycle'**
  String get billingCycle;

  /// No description provided for @billingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingMonthly;

  /// No description provided for @billingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get billingYearly;

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String pricePerMonth(String amount);

  /// No description provided for @pricePerYear.
  ///
  /// In en, this message translates to:
  /// **'{amount} / year'**
  String pricePerYear(String amount);

  /// No description provided for @nextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next renewal'**
  String get nextRenewal;

  /// No description provided for @subscriptionRenewed.
  ///
  /// In en, this message translates to:
  /// **'Renewed'**
  String get subscriptionRenewed;

  /// No description provided for @subscriptionRenewedOnQuestion.
  ///
  /// In en, this message translates to:
  /// **'When did it renew?'**
  String get subscriptionRenewedOnQuestion;

  /// No description provided for @subscriptionNextRenewalOn.
  ///
  /// In en, this message translates to:
  /// **'Next renewal: {date}'**
  String subscriptionNextRenewalOn(String date);

  /// No description provided for @paymentMethodOptional.
  ///
  /// In en, this message translates to:
  /// **'Payment method (optional)'**
  String get paymentMethodOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @renewsToday.
  ///
  /// In en, this message translates to:
  /// **'Renews today'**
  String get renewsToday;

  /// No description provided for @renewsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Renews tomorrow'**
  String get renewsTomorrow;

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Renews in 1 day} other{Renews in {daysText} days}}'**
  String renewsInDays(int days, String daysText);

  /// No description provided for @renewalPassed.
  ///
  /// In en, this message translates to:
  /// **'Renewal date passed'**
  String get renewalPassed;

  /// No description provided for @subscriptionSaved.
  ///
  /// In en, this message translates to:
  /// **'Subscription saved'**
  String get subscriptionSaved;

  /// No description provided for @subscriptionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Subscription deleted'**
  String get subscriptionDeleted;

  /// No description provided for @deleteSubscriptionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription?'**
  String get deleteSubscriptionQuestion;

  /// No description provided for @deleteSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'{name} and its reminders will be removed.'**
  String deleteSubscriptionBody(String name);

  /// No description provided for @currencyEgp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currencyEgp;

  /// No description provided for @subscriptionCategoryStreaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get subscriptionCategoryStreaming;

  /// No description provided for @subscriptionCategoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get subscriptionCategoryMusic;

  /// No description provided for @subscriptionCategoryGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get subscriptionCategoryGaming;

  /// No description provided for @subscriptionCategoryCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud storage'**
  String get subscriptionCategoryCloud;

  /// No description provided for @subscriptionCategoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get subscriptionCategoryProductivity;

  /// No description provided for @subscriptionCategoryAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get subscriptionCategoryAi;

  /// No description provided for @subscriptionCategoryDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get subscriptionCategoryDelivery;

  /// No description provided for @subscriptionCategoryTelecom.
  ///
  /// In en, this message translates to:
  /// **'Telecom & internet'**
  String get subscriptionCategoryTelecom;

  /// No description provided for @subscriptionCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get subscriptionCategoryOther;

  /// No description provided for @smartAdd.
  ///
  /// In en, this message translates to:
  /// **'Smart add'**
  String get smartAdd;

  /// No description provided for @smartAddHint.
  ///
  /// In en, this message translates to:
  /// **'From a screenshot or a bank SMS'**
  String get smartAddHint;

  /// No description provided for @smartAddTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get smartAddTakePhoto;

  /// No description provided for @smartAddChooseScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Choose a screenshot'**
  String get smartAddChooseScreenshot;

  /// No description provided for @smartAddPasteText.
  ///
  /// In en, this message translates to:
  /// **'Paste an SMS or email'**
  String get smartAddPasteText;

  /// No description provided for @smartAddPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the message'**
  String get smartAddPasteTitle;

  /// No description provided for @smartAddPasteHint.
  ///
  /// In en, this message translates to:
  /// **'For example, the bank SMS for the charge'**
  String get smartAddPasteHint;

  /// No description provided for @smartAddPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get smartAddPasteFromClipboard;

  /// No description provided for @smartAddPasteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Paste the message first'**
  String get smartAddPasteEmpty;

  /// No description provided for @smartAddRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get smartAddRead;

  /// No description provided for @smartAddReading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get smartAddReading;

  /// No description provided for @smartAddPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Full card numbers and email addresses are removed before the text is read.'**
  String get smartAddPrivacyNote;

  /// No description provided for @subscriptionScanUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a subscription in that. Try a clearer screenshot or the full message, or add it manually.'**
  String get subscriptionScanUnreadable;

  /// No description provided for @notifRenewalTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription renewing soon'**
  String get notifRenewalTitle;

  /// daysText is the day count in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{{name} renews today for {price}} =1{{name} renews tomorrow for {price}} other{{name} renews in {daysText} days for {price}}}'**
  String notifRenewalBody(int days, String daysText, String name, String price);

  /// No description provided for @subscriptionsAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsAnalyticsTitle;

  /// No description provided for @subscriptionsAnalyticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet. Tap to add Netflix, Spotify and more.'**
  String get subscriptionsAnalyticsEmpty;

  /// No description provided for @notifRenewedTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription renewed'**
  String get notifRenewedTitle;

  /// daysText is the day count in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{{name} renewed yesterday for {price}. Check you were charged the right amount.} other{{name} renewed {daysText} days ago for {price}. Check you were charged the right amount.}}'**
  String notifRenewedBody(int days, String daysText, String name, String price);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountActionsHint.
  ///
  /// In en, this message translates to:
  /// **'Log out or delete your account'**
  String get accountActionsHint;

  /// No description provided for @installments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installments;

  /// No description provided for @addInstallment.
  ///
  /// In en, this message translates to:
  /// **'Add installment'**
  String get addInstallment;

  /// No description provided for @editInstallment.
  ///
  /// In en, this message translates to:
  /// **'Edit installment plan'**
  String get editInstallment;

  /// No description provided for @installmentsLeftToPay.
  ///
  /// In en, this message translates to:
  /// **'Left to pay'**
  String get installmentsLeftToPay;

  /// No description provided for @installmentsHomeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Track Valu, bank and store installments'**
  String get installmentsHomeEmpty;

  /// No description provided for @noInstallmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No installments yet'**
  String get noInstallmentsYet;

  /// No description provided for @noInstallmentsBody.
  ///
  /// In en, this message translates to:
  /// **'Add what you\'re paying off with Valu, your bank or a store to see what\'s left and get reminded before each due date.'**
  String get noInstallmentsBody;

  /// countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active plans} one{1 active plan} other{{countText} active plans}}'**
  String installmentsActiveCount(int count, String countText);

  /// No description provided for @installmentsDueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} due this month'**
  String installmentsDueThisMonth(String amount);

  /// No description provided for @installmentsOverdueTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} overdue'**
  String installmentsOverdueTotal(String amount);

  /// countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 installment is overdue ({amount})} other{{countText} installments are overdue ({amount})}}'**
  String installmentsOverdueBanner(int count, String countText, String amount);

  /// Numbers already in the app's digits.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} paid'**
  String installmentsPaidOf(String paid, String total);

  /// No description provided for @installmentDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get installmentDueToday;

  /// No description provided for @installmentDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get installmentDueTomorrow;

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Due in 1 day} other{Due in {daysText} days}}'**
  String installmentDueInDays(int days, String daysText);

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Overdue by 1 day} other{Overdue by {daysText} days}}'**
  String installmentOverdueBy(int days, String daysText);

  /// No description provided for @installmentPaidOff.
  ///
  /// In en, this message translates to:
  /// **'Paid off'**
  String get installmentPaidOff;

  /// No description provided for @installmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get installmentCancelled;

  /// No description provided for @installmentOfTotal.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String installmentOfTotal(String amount);

  /// No description provided for @nextInstallment.
  ///
  /// In en, this message translates to:
  /// **'Next installment'**
  String get nextInstallment;

  /// No description provided for @nextInstallmentDue.
  ///
  /// In en, this message translates to:
  /// **'Next {amount} · {when}'**
  String nextInstallmentDue(String amount, String when);

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as unpaid'**
  String get markUnpaid;

  /// No description provided for @markUnpaidQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mark as unpaid?'**
  String get markUnpaidQuestion;

  /// No description provided for @markUnpaidBody.
  ///
  /// In en, this message translates to:
  /// **'The installment due {date} will show as unpaid again.'**
  String markUnpaidBody(String date);

  /// No description provided for @installmentMarkedPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid'**
  String get installmentMarkedPaid;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String paidOn(String date);

  /// No description provided for @paymentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Payment schedule'**
  String get paymentSchedule;

  /// No description provided for @linkedProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get linkedProduct;

  /// No description provided for @installmentProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get installmentProvider;

  /// No description provided for @installmentProviderOptional.
  ///
  /// In en, this message translates to:
  /// **'Provider (optional)'**
  String get installmentProviderOptional;

  /// No description provided for @providerBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get providerBank;

  /// No description provided for @providerStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get providerStore;

  /// No description provided for @downPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get downPayment;

  /// No description provided for @downPaymentOptional.
  ///
  /// In en, this message translates to:
  /// **'Down payment (optional)'**
  String get downPaymentOptional;

  /// No description provided for @downPaymentTooHigh.
  ///
  /// In en, this message translates to:
  /// **'More than the total price'**
  String get downPaymentTooHigh;

  /// No description provided for @interestOrFees.
  ///
  /// In en, this message translates to:
  /// **'Interest or fees'**
  String get interestOrFees;

  /// No description provided for @interestOrFeesOptional.
  ///
  /// In en, this message translates to:
  /// **'Interest / fees (optional)'**
  String get interestOrFeesOptional;

  /// No description provided for @installmentAmount.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installmentAmount;

  /// No description provided for @installmentsTimesAmount.
  ///
  /// In en, this message translates to:
  /// **'{count} × {amount}'**
  String installmentsTimesAmount(String count, String amount);

  /// No description provided for @installmentAmountPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly installment'**
  String get installmentAmountPerMonth;

  /// No description provided for @installmentAmountAuto.
  ///
  /// In en, this message translates to:
  /// **'Worked out from the total, down payment and fees.'**
  String get installmentAmountAuto;

  /// No description provided for @installmentAmountCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own amount.'**
  String get installmentAmountCustom;

  /// No description provided for @useEvenSplit.
  ///
  /// In en, this message translates to:
  /// **'Split evenly'**
  String get useEvenSplit;

  /// No description provided for @nothingLeftToFinance.
  ///
  /// In en, this message translates to:
  /// **'The down payment covers the whole price'**
  String get nothingLeftToFinance;

  /// No description provided for @installmentsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of installments'**
  String get installmentsCountLabel;

  /// No description provided for @installmentsCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 360'**
  String get installmentsCountInvalid;

  /// countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{At least 1: one is already paid} other{At least {countText}: that many are already paid}}'**
  String installmentsCountBelowPaid(int count, String countText);

  /// No description provided for @installmentsCountBelowPaidGeneric.
  ///
  /// In en, this message translates to:
  /// **'The number of installments can\'t be less than those already paid.'**
  String get installmentsCountBelowPaidGeneric;

  /// countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 month} other{{countText} months}}'**
  String monthsCount(int count, String countText);

  /// No description provided for @firstInstallmentDate.
  ///
  /// In en, this message translates to:
  /// **'First installment'**
  String get firstInstallmentDate;

  /// No description provided for @dueDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Due day'**
  String get dueDayOfMonth;

  /// No description provided for @dueDayValue.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of each month'**
  String dueDayValue(String day);

  /// No description provided for @dueDayShortMonthsHint.
  ///
  /// In en, this message translates to:
  /// **'In shorter months it\'s due on the last day.'**
  String get dueDayShortMonthsHint;

  /// No description provided for @installmentFor.
  ///
  /// In en, this message translates to:
  /// **'What are you paying for?'**
  String get installmentFor;

  /// No description provided for @installmentForProduct.
  ///
  /// In en, this message translates to:
  /// **'One of my products'**
  String get installmentForProduct;

  /// No description provided for @installmentForOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get installmentForOther;

  /// No description provided for @installmentTitle.
  ///
  /// In en, this message translates to:
  /// **'What did you buy?'**
  String get installmentTitle;

  /// No description provided for @installmentTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter what you bought'**
  String get installmentTitleRequired;

  /// No description provided for @chooseProduct.
  ///
  /// In en, this message translates to:
  /// **'Choose a product'**
  String get chooseProduct;

  /// No description provided for @chooseProductRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a product, or pick \"Something else\"'**
  String get chooseProductRequired;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search your products'**
  String get searchProducts;

  /// No description provided for @noProductsMatch.
  ///
  /// In en, this message translates to:
  /// **'No products match.'**
  String get noProductsMatch;

  /// No description provided for @noProductsToLink.
  ///
  /// In en, this message translates to:
  /// **'You have no products yet. Add one first, or pick \"Something else\".'**
  String get noProductsToLink;

  /// countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 installment is already paid and stays as it is. Changes apply to the rest.} other{{countText} installments are already paid and stay as they are. Changes apply to the rest.}}'**
  String editPaidInstallmentsNote(int count, String countText);

  /// No description provided for @schedulePreview.
  ///
  /// In en, this message translates to:
  /// **'Schedule preview'**
  String get schedulePreview;

  /// No description provided for @schedulePreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the total price and number of installments to see the schedule.'**
  String get schedulePreviewEmpty;

  /// total includes the down payment. countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 installment · {total} in total · last on {lastDate}} other{{countText} installments · {total} in total · last on {lastDate}}}'**
  String schedulePreviewSummary(
    int count,
    String countText,
    String total,
    String lastDate,
  );

  /// No description provided for @showAllInstallments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Show all {countText}}}'**
  String showAllInstallments(int count, String countText);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @installmentSaved.
  ///
  /// In en, this message translates to:
  /// **'Installment plan saved'**
  String get installmentSaved;

  /// No description provided for @installmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Installment plan deleted'**
  String get installmentDeleted;

  /// No description provided for @deleteInstallmentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete installment plan?'**
  String get deleteInstallmentQuestion;

  /// No description provided for @deleteInstallmentBody.
  ///
  /// In en, this message translates to:
  /// **'{name}, its payment schedule and reminders will be removed.'**
  String deleteInstallmentBody(String name);

  /// No description provided for @cancelInstallmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Cancel plan'**
  String get cancelInstallmentPlan;

  /// No description provided for @reactivateInstallmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Make active again'**
  String get reactivateInstallmentPlan;

  /// No description provided for @installmentPlanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Plan cancelled'**
  String get installmentPlanCancelled;

  /// No description provided for @installmentPlanReactivated.
  ///
  /// In en, this message translates to:
  /// **'Plan active again'**
  String get installmentPlanReactivated;

  /// No description provided for @installmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plan not found'**
  String get installmentNotFound;

  /// No description provided for @installmentNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get installmentNotFoundBody;

  /// No description provided for @productInstallmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Paying for this in installments? Track what\'s left and get reminded before each due date.'**
  String get productInstallmentsHint;

  /// No description provided for @notifInstallmentDueSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Installment due soon'**
  String get notifInstallmentDueSoonTitle;

  /// No description provided for @notifInstallmentDueTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Installment due today'**
  String get notifInstallmentDueTodayTitle;

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{{name}: {price} is due today} =1{{name}: {price} is due tomorrow} other{{name}: {price} is due in {daysText} days}}'**
  String notifInstallmentDueBody(
    int days,
    String daysText,
    String name,
    String price,
  );

  /// No description provided for @smartAddChoosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF (e.g. the contract)'**
  String get smartAddChoosePdf;

  /// No description provided for @smartAddInstallmentHint.
  ///
  /// In en, this message translates to:
  /// **'Fill this in from a contract, screenshot or SMS'**
  String get smartAddInstallmentHint;

  /// No description provided for @smartAddInstallmentReview.
  ///
  /// In en, this message translates to:
  /// **'Check every field before saving: nothing is saved until you tap the button below.'**
  String get smartAddInstallmentReview;

  /// No description provided for @installmentScanUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an installment plan in that. Try a clearer screenshot, the contract\'s first page or the full message, or fill it in yourself.'**
  String get installmentScanUnreadable;

  /// No description provided for @installmentsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Due this month'**
  String get installmentsThisMonth;

  /// No description provided for @installmentsDuePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Due each month'**
  String get installmentsDuePerMonth;

  /// No description provided for @installmentsAnalyticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No installments yet. Tap to add what you pay off monthly.'**
  String get installmentsAnalyticsEmpty;

  /// No description provided for @installmentsChartCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'The chart shows {currency} installments only'**
  String installmentsChartCurrencyNote(String currency);

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose which reminders Sakk sends on this phone.'**
  String get remindersIntro;

  /// No description provided for @remindersAllOff.
  ///
  /// In en, this message translates to:
  /// **'All off'**
  String get remindersAllOff;

  /// Joins a short list, e.g. "Warranties, Subscriptions".
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @reminderWarranties.
  ///
  /// In en, this message translates to:
  /// **'Warranties'**
  String get reminderWarranties;

  /// No description provided for @reminderWarrantiesHint.
  ///
  /// In en, this message translates to:
  /// **'Before a warranty ends, when it ends, and before a return window closes'**
  String get reminderWarrantiesHint;

  /// No description provided for @reminderSubscriptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Around each renewal'**
  String get reminderSubscriptionsHint;

  /// No description provided for @reminderInstallmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Before each installment is due'**
  String get reminderInstallmentsHint;

  /// No description provided for @reminderThreeDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get reminderThreeDaysBefore;

  /// No description provided for @reminderDayBefore.
  ///
  /// In en, this message translates to:
  /// **'The day before'**
  String get reminderDayBefore;

  /// No description provided for @reminderDayAfterCheckCharge.
  ///
  /// In en, this message translates to:
  /// **'The day after, to check the charge'**
  String get reminderDayAfterCheckCharge;

  /// No description provided for @reminderOnDueDay.
  ///
  /// In en, this message translates to:
  /// **'On the due day'**
  String get reminderOnDueDay;

  /// No description provided for @limitReachedProducts.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the free plan\'s product limit. Upgrade to Sakk Pro to add more.'**
  String get limitReachedProducts;

  /// No description provided for @limitReachedSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the free plan\'s subscription limit. Upgrade to Sakk Pro to track more.'**
  String get limitReachedSubscriptions;

  /// No description provided for @limitReachedInstallments.
  ///
  /// In en, this message translates to:
  /// **'The free plan tracks one running installment plan. Upgrade to Sakk Pro to add more.'**
  String get limitReachedInstallments;

  /// No description provided for @limitReachedScan.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free scans. Upgrade to Sakk Pro for unlimited scans, or try again tomorrow.'**
  String get limitReachedScan;

  /// No description provided for @limitReachedChat.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free messages. Upgrade to Sakk Pro, or come back tomorrow.'**
  String get limitReachedChat;

  /// No description provided for @limitReachedFairUse.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit. Please try again tomorrow.'**
  String get limitReachedFairUse;

  /// No description provided for @chatBusy.
  ///
  /// In en, this message translates to:
  /// **'The assistant is busy right now. Please try again in a minute.'**
  String get chatBusy;

  /// No description provided for @scanNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Scanning needs an internet connection. You can still enter the details yourself.'**
  String get scanNeedsInternet;

  /// No description provided for @chatNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'The assistant needs an internet connection.'**
  String get chatNeedsInternet;

  /// countText is the number in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No free scans left today} =1{1 scan left today} other{{countText} scans left today}}'**
  String scansLeftToday(int count, String countText);

  /// countText is the number in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No free messages left today} =1{1 message left today} other{{countText} messages left today}}'**
  String chatMessagesLeftToday(int count, String countText);

  /// No description provided for @planBadgeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planBadgeFree;

  /// No description provided for @planBadgePro.
  ///
  /// In en, this message translates to:
  /// **'Sakk Pro'**
  String get planBadgePro;

  /// No description provided for @planBadgeYearly.
  ///
  /// In en, this message translates to:
  /// **'Pro ⭐ Yearly'**
  String get planBadgeYearly;

  /// No description provided for @planBadgeTrial.
  ///
  /// In en, this message translates to:
  /// **'Pro – Trial'**
  String get planBadgeTrial;

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{ends today} =1{1 day left} other{{daysText} days left}}'**
  String planBadgeTrialDaysLeft(int days, String daysText);

  /// No description provided for @planBadgeBillingIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment issue'**
  String get planBadgeBillingIssue;

  /// No description provided for @sakkPro.
  ///
  /// In en, this message translates to:
  /// **'Sakk Pro'**
  String get sakkPro;

  /// No description provided for @proCardFreeBody.
  ///
  /// In en, this message translates to:
  /// **'Unlimited products, subscriptions and installments, unlimited AI, and your monthly summary.'**
  String get proCardFreeBody;

  /// No description provided for @proCardRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String proCardRenewsOn(String date);

  /// No description provided for @proCardEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Pro ends on {date}. Your data stays.'**
  String proCardEndsOn(String date);

  /// No description provided for @proCardTrialEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Free trial ends on {date}'**
  String proCardTrialEndsOn(String date);

  /// No description provided for @proCardBillingIssueBody.
  ///
  /// In en, this message translates to:
  /// **'Google Play couldn\'t charge your payment method. Update it to keep Pro.'**
  String get proCardBillingIssueBody;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @updatePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Update payment method'**
  String get updatePaymentMethod;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sakk Pro restored'**
  String get restoreSuccess;

  /// No description provided for @restoreNothing.
  ///
  /// In en, this message translates to:
  /// **'No Sakk Pro purchase found for this Google account'**
  String get restoreNothing;

  /// No description provided for @paywallHeadlineUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Get more out of Sakk'**
  String get paywallHeadlineUpgrade;

  /// No description provided for @paywallHeadlineScan.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free scans'**
  String get paywallHeadlineScan;

  /// No description provided for @paywallHeadlineChat.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free messages'**
  String get paywallHeadlineChat;

  /// No description provided for @paywallHeadlineProducts.
  ///
  /// In en, this message translates to:
  /// **'Your free plan is full'**
  String get paywallHeadlineProducts;

  /// No description provided for @paywallHeadlineSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Track all your subscriptions'**
  String get paywallHeadlineSubscriptions;

  /// No description provided for @paywallHeadlineInstallments.
  ///
  /// In en, this message translates to:
  /// **'Track all your installments'**
  String get paywallHeadlineInstallments;

  /// No description provided for @paywallHeadlineSummary.
  ///
  /// In en, this message translates to:
  /// **'See what you\'ll pay this month'**
  String get paywallHeadlineSummary;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No limits on products, subscriptions, installments or AI, plus smart reminders and your monthly summary.'**
  String get paywallSubtitle;

  /// No description provided for @paywallFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get paywallFeature;

  /// No description provided for @paywallFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywallFree;

  /// No description provided for @paywallPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get paywallPro;

  /// No description provided for @featureProducts.
  ///
  /// In en, this message translates to:
  /// **'Warranty products'**
  String get featureProducts;

  /// No description provided for @featureSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Tracked subscriptions'**
  String get featureSubscriptions;

  /// No description provided for @featureInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get featureInstallments;

  /// No description provided for @featureScans.
  ///
  /// In en, this message translates to:
  /// **'AI scans'**
  String get featureScans;

  /// No description provided for @featureChat.
  ///
  /// In en, this message translates to:
  /// **'AI chat messages'**
  String get featureChat;

  /// No description provided for @featureReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get featureReminders;

  /// No description provided for @featureSummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly summary'**
  String get featureSummary;

  /// No description provided for @valuePerDay.
  ///
  /// In en, this message translates to:
  /// **'{countText}/day'**
  String valuePerDay(String countText);

  /// No description provided for @valueUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get valueUnlimited;

  /// No description provided for @valueBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get valueBasic;

  /// No description provided for @valueSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get valueSmart;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @savePercent.
  ///
  /// In en, this message translates to:
  /// **'Save ~{percent}%'**
  String savePercent(String percent);

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1-day free trial} other{{daysText}-day free trial}}'**
  String freeTrialDays(int days, String daysText);

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start free trial'**
  String get startFreeTrial;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// days is the trial length in the app's digits; count picks the plural form; price is e.g. "EGP 29.00 / month".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Free for 1 day} other{Free for {days} days}}, then {price}. Cancel before the trial ends and you won\'t be charged.'**
  String autoRenewTrialDisclosure(int count, String days, String price);

  /// No description provided for @autoRenewDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Payment is charged to your Google Play account. The subscription renews automatically at the price shown unless you cancel at least 24 hours before the current period ends. Manage or cancel anytime in Google Play → Payments & subscriptions.'**
  String get autoRenewDisclosure;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sakk Pro!'**
  String get purchaseSuccess;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through. Please try again.'**
  String get purchaseFailed;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Your payment is pending. Sakk Pro unlocks as soon as Google Play confirms it.'**
  String get purchasePending;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore your purchases. Please try again.'**
  String get restoreFailed;

  /// No description provided for @purchasesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions aren\'t available right now. Please try again later.'**
  String get purchasesUnavailable;

  /// No description provided for @proComingSoonIos.
  ///
  /// In en, this message translates to:
  /// **'Sakk Pro is coming soon on iPhone. You can keep using the free plan until then.'**
  String get proComingSoonIos;

  /// No description provided for @alreadyPro.
  ///
  /// In en, this message translates to:
  /// **'You\'re on Sakk Pro'**
  String get alreadyPro;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get monthlySummary;

  /// No description provided for @monthlySummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Left to pay this month'**
  String get monthlySummaryTotal;

  /// No description provided for @monthlySummaryTotalHint.
  ///
  /// In en, this message translates to:
  /// **'Subscription renewals and unpaid installments from today to the end of the month, overdue ones included.'**
  String get monthlySummaryTotalHint;

  /// No description provided for @monthlySummaryUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payments'**
  String get monthlySummaryUpcoming;

  /// No description provided for @monthlySummaryNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to pay this month.'**
  String get monthlySummaryNothingDue;

  /// No description provided for @monthlySummaryWarranties.
  ///
  /// In en, this message translates to:
  /// **'Warranties ending soon'**
  String get monthlySummaryWarranties;

  /// No description provided for @monthlySummaryNoWarranties.
  ///
  /// In en, this message translates to:
  /// **'No warranties end in the next 60 days.'**
  String get monthlySummaryNoWarranties;

  /// No description provided for @monthlySummaryOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get monthlySummaryOverdue;

  /// No description provided for @summaryRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renewal'**
  String get summaryRenewal;

  /// No description provided for @summaryInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get summaryInstallment;

  /// No description provided for @reminderCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Earlier reminder'**
  String get reminderCustomTitle;

  /// No description provided for @reminderCustomHint.
  ///
  /// In en, this message translates to:
  /// **'One more reminder, this many days before'**
  String get reminderCustomHint;

  /// No description provided for @reminderCustomOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderCustomOff;

  /// daysText is the number in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{{daysText} days}}'**
  String reminderCustomDays(int days, String daysText);

  /// No description provided for @reminderCustomProOnly.
  ///
  /// In en, this message translates to:
  /// **'Sakk Pro'**
  String get reminderCustomProOnly;

  /// No description provided for @paywallHeadlinePdfReport.
  ///
  /// In en, this message translates to:
  /// **'Get everything in one PDF'**
  String get paywallHeadlinePdfReport;

  /// No description provided for @featurePdfReport.
  ///
  /// In en, this message translates to:
  /// **'PDF report'**
  String get featurePdfReport;

  /// No description provided for @proStatusLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your plan. Check your connection and try again.'**
  String get proStatusLoadFailed;

  /// No description provided for @pdfReportExport.
  ///
  /// In en, this message translates to:
  /// **'Export PDF report'**
  String get pdfReportExport;

  /// No description provided for @pdfReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the report. Please try again.'**
  String get pdfReportFailed;

  /// No description provided for @pdfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sakk report'**
  String get pdfReportTitle;

  /// No description provided for @pdfReportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String pdfReportGenerated(String date);

  /// No description provided for @pdfReportSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get pdfReportSummary;

  /// No description provided for @pdfReportNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get pdfReportNone;

  /// No description provided for @pdfReportPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pdfReportPage(String page, String total);

  /// No description provided for @pdfColNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next payment'**
  String get pdfColNextDue;

  /// No description provided for @pdfColPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get pdfColPaid;

  /// No description provided for @pdfColRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get pdfColRemaining;

  /// No description provided for @pdfColPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get pdfColPlan;

  /// No description provided for @pdfColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pdfColStatus;

  /// No description provided for @pdfRemainingInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments left to pay'**
  String get pdfRemainingInstallments;

  /// No description provided for @addByVoice.
  ///
  /// In en, this message translates to:
  /// **'Add by voice'**
  String get addByVoice;

  /// No description provided for @voiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell Sakk what you bought'**
  String get voiceTitle;

  /// No description provided for @voiceExample.
  ///
  /// In en, this message translates to:
  /// **'For example: \"I bought a Samsung 55-inch TV from B.TECH today for 20,000, with a 2-year warranty.\"'**
  String get voiceExample;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get voiceListening;

  /// No description provided for @voiceDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get voiceDone;

  /// No description provided for @voiceMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Sakk needs the microphone to add by voice. Allow it in your phone\'s settings.'**
  String get voiceMicDenied;

  /// No description provided for @voiceRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t record. Please try again.'**
  String get voiceRecordFailed;

  /// No description provided for @voiceUnheard.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t make out a product. Try again and say the product, the store, the price and the warranty.'**
  String get voiceUnheard;

  /// No description provided for @voiceNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Adding by voice needs an internet connection.'**
  String get voiceNeedsInternet;

  /// No description provided for @voiceYouSaid.
  ///
  /// In en, this message translates to:
  /// **'You said'**
  String get voiceYouSaid;

  /// No description provided for @paywallHeadlineVoice.
  ///
  /// In en, this message translates to:
  /// **'Add products just by saying them'**
  String get paywallHeadlineVoice;

  /// No description provided for @featureVoice.
  ///
  /// In en, this message translates to:
  /// **'Add by voice'**
  String get featureVoice;

  /// No description provided for @limitReachedVoice.
  ///
  /// In en, this message translates to:
  /// **'Add by voice is part of Sakk Pro.'**
  String get limitReachedVoice;

  /// No description provided for @voiceUnheardTitle.
  ///
  /// In en, this message translates to:
  /// **'We didn\'t catch that'**
  String get voiceUnheardTitle;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo (optional)'**
  String get addPhoto;

  /// No description provided for @addPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'The receipt, the box or the product'**
  String get addPhotoHint;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @myPapers.
  ///
  /// In en, this message translates to:
  /// **'My papers'**
  String get myPapers;

  /// No description provided for @papersHomeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your ID, passport and licences'**
  String get papersHomeEmpty;

  /// No description provided for @addPaper.
  ///
  /// In en, this message translates to:
  /// **'Add paper'**
  String get addPaper;

  /// No description provided for @editPaper.
  ///
  /// In en, this message translates to:
  /// **'Edit paper'**
  String get editPaper;

  /// No description provided for @noPapersYet.
  ///
  /// In en, this message translates to:
  /// **'No papers yet'**
  String get noPapersYet;

  /// No description provided for @noPapersBody.
  ///
  /// In en, this message translates to:
  /// **'Save your ID, passport, licences and insurance cards with a photo and the expiry date. Sakk reminds you a month before each one expires.'**
  String get noPapersBody;

  /// No description provided for @papersPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your papers are private to your account: they aren\'t shared with your household, other users can\'t open them, and they\'re never sent to the AI.'**
  String get papersPrivacyNote;

  /// No description provided for @paperNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get paperNationalId;

  /// No description provided for @paperPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get paperPassport;

  /// No description provided for @paperDrivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get paperDrivingLicence;

  /// No description provided for @paperCarLicence.
  ///
  /// In en, this message translates to:
  /// **'Car licence'**
  String get paperCarLicence;

  /// No description provided for @paperCarInsurance.
  ///
  /// In en, this message translates to:
  /// **'Car insurance'**
  String get paperCarInsurance;

  /// No description provided for @paperHealthInsurance.
  ///
  /// In en, this message translates to:
  /// **'Medical insurance'**
  String get paperHealthInsurance;

  /// No description provided for @paperRentalContract.
  ///
  /// In en, this message translates to:
  /// **'Rental contract'**
  String get paperRentalContract;

  /// No description provided for @paperOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get paperOther;

  /// No description provided for @paperType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get paperType;

  /// No description provided for @paperName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get paperName;

  /// No description provided for @paperNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get paperNameOptional;

  /// No description provided for @paperViewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get paperViewPhoto;

  /// No description provided for @paperNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this paper'**
  String get paperNameRequired;

  /// No description provided for @paperNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Number (optional)'**
  String get paperNumberOptional;

  /// No description provided for @paperExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get paperExpiryDate;

  /// No description provided for @paperPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get paperPickDate;

  /// No description provided for @paperNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t expire'**
  String get paperNoExpiry;

  /// No description provided for @paperPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional)'**
  String get paperPhotos;

  /// No description provided for @paperFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get paperFront;

  /// No description provided for @paperBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get paperBack;

  /// No description provided for @paperRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get paperRemovePhoto;

  /// No description provided for @paperSaved.
  ///
  /// In en, this message translates to:
  /// **'Paper saved'**
  String get paperSaved;

  /// No description provided for @paperDeleted.
  ///
  /// In en, this message translates to:
  /// **'Paper deleted'**
  String get paperDeleted;

  /// No description provided for @deletePaperQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete paper?'**
  String get deletePaperQuestion;

  /// No description provided for @deletePaperBody.
  ///
  /// In en, this message translates to:
  /// **'{name} and its photos will be deleted.'**
  String deletePaperBody(String name);

  /// No description provided for @paperExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get paperExpiresToday;

  /// daysText is the day count in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Expires tomorrow} other{Expires in {daysText} days}}'**
  String paperExpiresInDays(int days, String daysText);

  /// No description provided for @paperValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String paperValidUntil(String date);

  /// No description provided for @paperExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired on {date}'**
  String paperExpiredOn(String date);

  /// No description provided for @paperNoExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'No expiry date'**
  String get paperNoExpiryDate;

  /// No description provided for @paperStatusValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get paperStatusValid;

  /// No description provided for @paperStatusExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get paperStatusExpiringSoon;

  /// No description provided for @paperStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get paperStatusExpired;

  /// No description provided for @paperNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get paperNumber;

  /// No description provided for @copyPaperNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get copyPaperNumber;

  /// No description provided for @paperNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get paperNumberCopied;

  /// No description provided for @paperNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos. Tap Edit to add the front and back.'**
  String get paperNoPhotos;

  /// No description provided for @notifPaperExpiringTitle.
  ///
  /// In en, this message translates to:
  /// **'Paper expiring soon'**
  String get notifPaperExpiringTitle;

  /// No description provided for @notifPaperExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Paper expired'**
  String get notifPaperExpiredTitle;

  /// daysText is the day count in the app's digits; days picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{{name} expires tomorrow. Time to renew it.} other{{name} expires in {daysText} days. Time to renew it.}}'**
  String notifPaperExpiringBody(int days, String daysText, String name);

  /// No description provided for @notifPaperExpiresTodayBody.
  ///
  /// In en, this message translates to:
  /// **'{name} expires today.'**
  String notifPaperExpiresTodayBody(String name);

  /// No description provided for @notifPaperExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'{name} has expired. Renew it as soon as you can.'**
  String notifPaperExpiredBody(String name);

  /// No description provided for @reminderPapersHint.
  ///
  /// In en, this message translates to:
  /// **'Before each paper expires'**
  String get reminderPapersHint;

  /// No description provided for @reminderMonthBefore.
  ///
  /// In en, this message translates to:
  /// **'A month before'**
  String get reminderMonthBefore;

  /// No description provided for @reminderWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'A week before'**
  String get reminderWeekBefore;

  /// No description provided for @reminderOnExpiryDay.
  ///
  /// In en, this message translates to:
  /// **'On the expiry day'**
  String get reminderOnExpiryDay;

  /// No description provided for @featurePapers.
  ///
  /// In en, this message translates to:
  /// **'Papers'**
  String get featurePapers;

  /// No description provided for @paywallHeadlinePapers.
  ///
  /// In en, this message translates to:
  /// **'Keep all your papers in one place'**
  String get paywallHeadlinePapers;

  /// No description provided for @limitReachedPapers.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the free plan\'s paper limit. Upgrade to Sakk Pro to add more.'**
  String get limitReachedPapers;

  /// No description provided for @statProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get statProducts;

  /// No description provided for @statActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statActive;

  /// No description provided for @statExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get statExpiring;

  /// No description provided for @statExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statExpired;

  /// No description provided for @moneyThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Money this month'**
  String get moneyThisMonth;

  /// No description provided for @subscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get subscriptionPlan;

  /// No description provided for @subscriptionPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get subscriptionPaymentMethod;

  /// No description provided for @subscriptionMonthlyEquivalent.
  ///
  /// In en, this message translates to:
  /// **'That\'s {amount} a month'**
  String subscriptionMonthlyEquivalent(String amount);

  /// No description provided for @papersNeedRenewing.
  ///
  /// In en, this message translates to:
  /// **'Needs renewing'**
  String get papersNeedRenewing;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs renewing} other{{countText} need renewing}}'**
  String papersToRenewCount(int count, String countText);

  /// No description provided for @papersAllUpToDate.
  ///
  /// In en, this message translates to:
  /// **'All up to date'**
  String get papersAllUpToDate;

  /// countText is the count in the app's digits; count picks the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 paper} other{{countText} papers}}'**
  String papersCountLabel(int count, String countText);

  /// No description provided for @scanCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the receipt or warranty card'**
  String get scanCameraHint;

  /// No description provided for @scanOtherWays.
  ///
  /// In en, this message translates to:
  /// **'Other ways to add'**
  String get scanOtherWays;

  /// No description provided for @scanGalleryHint.
  ///
  /// In en, this message translates to:
  /// **'A photo you already have'**
  String get scanGalleryHint;

  /// No description provided for @scanPdfHint.
  ///
  /// In en, this message translates to:
  /// **'An invoice a store emailed you'**
  String get scanPdfHint;

  /// No description provided for @scanVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Say what you bought and we fill it in'**
  String get scanVoiceHint;

  /// No description provided for @scanManualHint.
  ///
  /// In en, this message translates to:
  /// **'No receipt? Type the details in'**
  String get scanManualHint;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodThisMonth;

  /// No description provided for @periodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get periodThisYear;

  /// No description provided for @periodAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAllTime;

  /// No description provided for @analyticsMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get analyticsMoney;

  /// No description provided for @installmentSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get installmentSectionDetails;

  /// No description provided for @installmentSectionPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get installmentSectionPrice;

  /// No description provided for @installmentSectionPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get installmentSectionPayments;

  /// No description provided for @analyticsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stats yet'**
  String get analyticsEmptyTitle;

  /// No description provided for @analyticsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to see your spending, warranties and categories here.'**
  String get analyticsEmptyMessage;

  /// No description provided for @analyticsProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 product} other{{countText} products}}'**
  String analyticsProductsCount(int count, String countText);

  /// No description provided for @analyticsAverage.
  ///
  /// In en, this message translates to:
  /// **'avg {amount}'**
  String analyticsAverage(String amount);

  /// No description provided for @analyticsShowAllCategories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Show all {countText}}}'**
  String analyticsShowAllCategories(int count, String countText);
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
