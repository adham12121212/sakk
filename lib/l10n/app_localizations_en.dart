// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInWithBiometrics => 'Sign in with Face ID / Touch ID';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get appName => 'Sakk';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinSakkToday => 'Join Sakk today';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameHint => 'Ahmed Al-Omari';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneHint => '+020 5x xxx xxxx';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get agreeToTermsPrefix => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get and => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get pleaseAgreeToTerms =>
      'Please agree to the Terms of Service and Privacy Policy';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get confirmPasswordRequired => 'Confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get saveProduct => 'Save Product';

  @override
  String get productName => 'Product Name';

  @override
  String get notes => 'Notes';

  @override
  String get brand => 'Brand';

  @override
  String get price => 'Price';

  @override
  String get warrantyMonths => 'Warranty (months)';

  @override
  String get store => 'Store';

  @override
  String get purchaseDate => 'Purchase Date';

  @override
  String get productImage => 'Product Image';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get productNameRequired => 'Product name is required';

  @override
  String get warrantyRequired => 'Warranty length is required';

  @override
  String get priceEgp => 'Price (EGP)';

  @override
  String get productSavedSuccessfully => 'Product saved successfully';

  @override
  String get invalidWarrantyMonths => 'Enter a valid number of months';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get analytics => 'Analytics';

  @override
  String get totalSpant => 'Total Spent';

  @override
  String get preferences => 'Preferences';

  @override
  String get proUser => 'Pro User';

  @override
  String get products => 'Products';

  @override
  String get active => 'Active';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAuto => 'Auto';

  @override
  String get logOut => 'Log Out';

  @override
  String get logOutConfirmTitle => 'Log out?';

  @override
  String get logOutConfirmBody =>
      'You\'ll need to sign in again to access your products.';

  @override
  String get cancel => 'Cancel';

  @override
  String get warrantyStatus => 'Warranty Status';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get expiring => 'Expiring';

  @override
  String get expired => 'Expired';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get welcomeback => 'Welcome back!';

  @override
  String get welcometoSakk => 'Welcome to Sakk!';

  @override
  String get atleast8characters => 'At least 8 characters';

  @override
  String get categories => 'Categories';

  @override
  String get product => 'product';

  @override
  String get electronics => 'Electronics';

  @override
  String get appliances => 'Appliances';

  @override
  String get furniture => 'Furniture';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get accessories => 'Accessories';

  @override
  String get other => 'Other';

  @override
  String get aIAssistant => 'AI Assistant';

  @override
  String get howdoIaddanewproduct => 'How do I add a new product?';

  @override
  String get whatshouldIdoifaproductbreaks =>
      'What should I do if a product breaks?';

  @override
  String get askmeanything => 'Ask me anything';

  @override
  String get icanhelpwithyourproductswarrantiesandpurchases =>
      'I can help with your products, warranties, and purchases.';

  @override
  String get askaboutaproductorwarranty => 'Ask about a product or warranty…';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get category => 'Category';

  @override
  String get productUpdated => 'Product updated';

  @override
  String get deleteProductQuestion => 'Delete product?';

  @override
  String deleteProductConfirmBody(Object productName) {
    return '\"$productName\" will be permanently removed. This can\'t be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get downloadInvoice => 'Download Invoice';

  @override
  String get noInvoiceAvailable => 'No invoice available';

  @override
  String couldNotOpenShareSheet(Object error) {
    return 'Couldn\'t open the share sheet: $error';
  }

  @override
  String get noInvoiceImageToDownload =>
      'No invoice image to download for this product.';

  @override
  String downloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get couldNotDeleteProduct =>
      'Couldn\'t delete this product. Please try again.';

  @override
  String get warrantyPeriod => 'Warranty Period';

  @override
  String get detailsTab => 'Details';

  @override
  String get invoiceTab => 'Invoice';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get warrantyExpired => 'Warranty expired';

  @override
  String expiresOnLabel(Object date) {
    return 'Expires on: $date';
  }

  @override
  String shareBrand(Object brand) {
    return 'Brand: $brand';
  }

  @override
  String shareStore(Object store) {
    return 'Store: $store';
  }

  @override
  String sharePrice(Object currency, Object price) {
    return 'Price: $currency $price';
  }

  @override
  String sharePurchased(Object date) {
    return 'Purchased: $date';
  }

  @override
  String shareWarranty(Object months) {
    return 'Warranty: $months months';
  }

  @override
  String shareExpires(Object date) {
    return 'Expires: $date';
  }

  @override
  String shareInvoiceUrl(Object url) {
    return '\nInvoice: $url';
  }

  @override
  String invoiceShareText(Object name) {
    return 'Invoice — $name';
  }

  @override
  String get months => 'months';

  @override
  String get enteryouremailandwellsendyouacodetoresetyourpassword =>
      'Enter your email and we\'ll send you a code to reset your password.';

  @override
  String get sendCode => 'Send Code';

  @override
  String get passwordupdatedpleasesigninagain =>
      'Password updated please sign in again';

  @override
  String get enterCode => 'Enter Code';

  @override
  String weSentCodeTo(Object email, Object length) {
    return 'We sent a $length-digit code to $email';
  }

  @override
  String get newCodeSentToEmail => 'A new code was sent to your email';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String enterDigitCode(Object length) {
    return 'Enter the $length-digit code';
  }

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get chooseNewPasswordSubtitle =>
      'Choose a new password for your account.';

  @override
  String get updatePasswordButton => 'Update Password';

  @override
  String get recentProducts => 'Recent Products';

  @override
  String get seeAll => 'See all';

  @override
  String get retry => 'Retry';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get activeWarranties => 'Active Warranties';

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String warrantiesExpiringSoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warranties are expiring soon',
      one: '1 warranty is expiring soon',
    );
    return '$_temp0';
  }

  @override
  String get goodMorning => 'Good morning,';

  @override
  String get goodAfternoon => 'Good afternoon,';

  @override
  String get goodEvening => 'Good evening,';

  @override
  String get goodNight => 'Good night,';

  @override
  String get guestFallbackName => 'there';

  @override
  String get home => 'Home';

  @override
  String get scan => 'Scan';

  @override
  String get ai => 'AI';

  @override
  String get notifications => 'Notifications';

  @override
  String get nonotificationsyet => 'No notifications yet';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get onboardingScanTitle => 'Scan Your Receipts';

  @override
  String get onboardingScanDescription =>
      'Snap a photo of any receipt or warranty card and let AI pull out the details automatically.';

  @override
  String get onboardingTrackTitle => 'Track Every Warranty';

  @override
  String get onboardingTrackDescription =>
      'See at a glance which products are active, expiring soon, or already expired.';

  @override
  String get onboardingNotifyTitle => 'Never Miss a Deadline';

  @override
  String get onboardingNotifyDescription =>
      'Get notified before a warranty runs out, so you never lose coverage you\'re entitled to.';

  @override
  String get appTagline => 'Sakk — AI Warranty Manager';

  @override
  String get myProducts => 'My Products';

  @override
  String get all => 'All';

  @override
  String get nothingInThisFilter => 'Nothing in this filter';

  @override
  String get searchProductsHint => 'Search products...';

  @override
  String noProductsMatchQuery(Object query) {
    return 'No products match \"$query\"';
  }

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get couldNotReadReceipt => 'Couldn\'t read that receipt';

  @override
  String get tryAnotherPhoto => 'Try Another Photo';

  @override
  String get aiIsProcessing => 'AI is Processing';

  @override
  String get extractionComplete => 'Extraction Complete';

  @override
  String get extractingData => 'Extracting Data...';

  @override
  String get progressLabel => 'Progress';

  @override
  String get back => 'Back';

  @override
  String get scanReceiptTitle => 'Scan Receipt';

  @override
  String get scanYourWarrantyReceipt => 'Scan your warranty receipt';

  @override
  String get scanInstructions =>
      'We\'ll pull out the product, price, and warranty info automatically.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get confidenceScoreLabel => 'Confidence Score: ';

  @override
  String get doubleCheckFieldsBelow => 'Please double-check the fields below.';

  @override
  String get lowConfidenceWarning =>
      'We weren\'t fully confident reading this receipt — please double-check every field.';

  @override
  String get invoicePreviewLabel => 'Invoice Preview';

  @override
  String priceSar(Object price) {
    return 'SAR $price';
  }

  @override
  String get warrantyDuration => 'Warranty Duration';

  @override
  String warrantyMonthsValue(Object months) {
    return '$months months';
  }

  @override
  String get verifyDetails => 'Verify Details';

  @override
  String get reviewAndEditExtractedData => 'Review and edit extracted data';
}
