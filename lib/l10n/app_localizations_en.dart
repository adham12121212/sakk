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
  String get priceEgp => 'Price(EGP)';

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
      'Snap a photo of a receipt or warranty card, or upload a PDF invoice, and AI fills in the details for you.';

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
  String get warrantyDuration => 'Warranty Duration';

  @override
  String warrantyMonthsValue(Object months) {
    return '$months months';
  }

  @override
  String get verifyDetails => 'Verify Details';

  @override
  String get reviewAndEditExtractedData => 'Review and edit extracted data';

  @override
  String get biometricLogin => 'Login with Face ID / Fingerprint';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication isn\'t available on this device.';

  @override
  String get biometricConfirmEnableReason =>
      'Confirm to enable Face ID / Fingerprint login';

  @override
  String get biometricUnlockReason => 'Unlock Sakk to continue';

  @override
  String get appLockedTitle => 'Sakk is locked';

  @override
  String get appLockedSubtitle =>
      'Use Face ID or your fingerprint to continue.';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get usePasswordInstead => 'Use password instead';

  @override
  String get biometricRequiresActiveSession =>
      'Sign in with your password first to enable quick biometric access.';

  @override
  String get biometricNotEnabledYet =>
      'Biometric login isn\'t enabled yet. Turn it on from Profile settings.';

  @override
  String scannedPriceValue(Object price) {
    return '$price EGP';
  }

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountWarning =>
      'This permanently deletes your account, all your products, receipts and notifications. This can\'t be undone.';

  @override
  String get deleteAccountKeyword => 'DELETE';

  @override
  String deleteAccountTypeToConfirm(String keyword) {
    return 'Type $keyword to confirm';
  }

  @override
  String get deleteAccountConfirm => 'Delete forever';

  @override
  String get accountDeleted => 'Your account has been deleted';

  @override
  String get search => 'Search';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get clearCategoryFilter => 'Clear category filter';

  @override
  String get openProfile => 'Open profile';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get sendMessage => 'Send message';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get errorNoInternet =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get couldNotShare =>
      'Couldn\'t open the share sheet. Please try again.';

  @override
  String get couldNotDownloadInvoice =>
      'Couldn\'t save the invoice. Please try again.';

  @override
  String unreadNotificationsLabel(int count, String formattedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formattedCount unread notifications',
      one: '$formattedCount unread notification',
    );
    return '$_temp0';
  }

  @override
  String get offlineBanner => 'You\'re offline. Showing saved data.';

  @override
  String get backOnlineBanner => 'Back online';

  @override
  String get errorOfflineTitle => 'You\'re offline';

  @override
  String get errorOfflineBody =>
      'Check your internet connection, then try again.';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody =>
      'We couldn\'t load this right now. Please try again in a moment.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get messageNotSent => 'Not sent. Tap to retry';

  @override
  String get enterDetailsManually => 'Enter details manually';

  @override
  String get addProductManuallyTitle => 'Add Product';

  @override
  String get addProductManuallySubtitle => 'Fill in your product\'s details';

  @override
  String get warrantyReminder => 'Remind me before warranty ends';

  @override
  String get reminder3Months => '3 mo';

  @override
  String get reminder1Month => '1 mo';

  @override
  String get reminder1Week => '1 wk';

  @override
  String get reminder1Day => '1 day';

  @override
  String get warrantyEnds => 'Warranty ends';

  @override
  String get status => 'Status';

  @override
  String get exportProducts => 'Export products';

  @override
  String get returnWindowDays => 'Return window (days, optional)';

  @override
  String get invalidReturnDays =>
      'Enter a number from 1 to 365, or leave it empty';

  @override
  String get returnBy => 'Return by';

  @override
  String returnByValue(Object date, num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'last day',
    );
    return '$date ($_temp0)';
  }

  @override
  String returnWindowClosed(Object date) {
    return 'Closed on $date';
  }

  @override
  String get coveredUntil => 'Covered until';

  @override
  String get extraWarranties => 'Extra warranties';

  @override
  String get extraWarrantiesHint =>
      'Bought an extended warranty? Add it so reminders use the right date.';

  @override
  String get addWarranty => 'Add warranty';

  @override
  String get warrantyProvider => 'Provider';

  @override
  String get warrantyProviderHint => 'e.g. B.TECH extended warranty';

  @override
  String get warrantyProviderRequired => 'Enter who gives this warranty';

  @override
  String get warrantyStartDate => 'Start date';

  @override
  String get warrantyClaims => 'Warranty claims';

  @override
  String get warrantyClaimsHint =>
      'Something broke? Start a claim to get a ready-to-send message and track its status.';

  @override
  String get startClaim => 'Start a claim';

  @override
  String get startClaimExplanation =>
      'Describe the problem. We\'ll save the claim and prepare a message with the product and invoice details that you can send by WhatsApp or email.';

  @override
  String get claimIssue => 'What\'s wrong?';

  @override
  String get claimIssueHint => 'e.g. The screen stopped turning on';

  @override
  String get claimIssueRequired => 'Describe the problem';

  @override
  String get saveAndSendClaim => 'Save and send';

  @override
  String claimSubject(Object product) {
    return 'Warranty claim: $product';
  }

  @override
  String claimMessageIntro(
    Object endDate,
    Object product,
    Object purchaseDate,
  ) {
    return 'Hello, I\'d like to make a warranty claim for my $product, bought on $purchaseDate. It is under warranty until $endDate.';
  }

  @override
  String claimMessageIssue(Object issue) {
    return 'Problem: $issue';
  }

  @override
  String get claimStatus => 'Claim status';

  @override
  String get claimSubmitted => 'Submitted';

  @override
  String get claimInRepair => 'In repair';

  @override
  String get claimResolved => 'Resolved';

  @override
  String get claimRejected => 'Rejected';

  @override
  String get deleteClaim => 'Delete claim';

  @override
  String get widgetNextToEnd => 'Next warranty to end';

  @override
  String widgetEndsOn(Object date) {
    return 'Ends $date';
  }

  @override
  String get widgetNoWarranties => 'No active warranties';

  @override
  String get widgetSignedOut => 'Open Sakk to see your warranties';

  @override
  String get hideTotalSpent => 'Hide total spent';

  @override
  String get showTotalSpent => 'Show total spent';

  @override
  String get totalSpentHidden => 'Total spent hidden';

  @override
  String get invoiceSavedToPhotos => 'Invoice saved to your photos';

  @override
  String get serialNumber => 'Serial number';

  @override
  String get invoiceNumber => 'Invoice number';

  @override
  String foreignPriceHint(Object amount) {
    return 'The receipt shows $amount. Enter the price in EGP.';
  }

  @override
  String get scanUnreadable =>
      'We couldn\'t read that photo. Try a clearer, well-lit photo of the receipt, or enter the details manually.';

  @override
  String get scanBusy =>
      'Too many scans right now. Please try again in a minute.';

  @override
  String get uploadPdfInvoice => 'Upload PDF Invoice';

  @override
  String get pdfUnreadable =>
      'We couldn\'t open that PDF. If it\'s password-protected, remove the password and try again.';

  @override
  String get duplicateTitle => 'Already added?';

  @override
  String get duplicateSameInvoice =>
      'You already have a product with this invoice number.';

  @override
  String get duplicateSameSerial =>
      'You already have a product with this serial number.';

  @override
  String get duplicateSameNameAndDate =>
      'You already have this product, bought on the same day.';

  @override
  String duplicateExisting(Object date, Object name) {
    return 'Saved: $name, bought $date.';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get familySharing => 'Family sharing';

  @override
  String get familySharingHint =>
      'Create a household to share your products with your family, or join one with an invite code.';

  @override
  String get createHousehold => 'Create';

  @override
  String get joinHousehold => 'Join';

  @override
  String get householdName => 'Household name';

  @override
  String get householdNameHint => 'e.g. The Ahmeds';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get householdCreated =>
      'Household created. Share the invite code with your family.';

  @override
  String get householdJoined => 'You joined the household.';

  @override
  String get householdSharedHint =>
      'Members see each other\'s products. Only the person who added a product can edit it.';

  @override
  String get copyInviteCode => 'Copy invite code';

  @override
  String get inviteCodeCopied => 'Invite code copied';

  @override
  String get shareInviteCode => 'Share invite code';

  @override
  String inviteMessage(Object code, Object name) {
    return 'Join our household \"$name\" in Sakk with this invite code: $code';
  }

  @override
  String get newInviteCode => 'Make a new code';

  @override
  String get newInviteCodeCreated =>
      'New invite code created. The old one no longer works.';

  @override
  String get householdMembers => 'Members';

  @override
  String memberYou(Object name) {
    return '$name (you)';
  }

  @override
  String get householdOwner => 'Owner';

  @override
  String get removeMember => 'Remove';

  @override
  String removeMemberQuestion(Object name) {
    return 'Remove $name?';
  }

  @override
  String get removeMemberBody =>
      'They will no longer see the household\'s products, and you won\'t see theirs.';

  @override
  String get leaveHousehold => 'Leave household';

  @override
  String get leaveHouseholdQuestion => 'Leave the household?';

  @override
  String get leaveHouseholdBody =>
      'You\'ll stop seeing the other members\' products, and they\'ll stop seeing yours.';

  @override
  String addedBy(Object name) {
    return 'Added by $name';
  }

  @override
  String get addedByHouseholdMember => 'Added by a household member';

  @override
  String get invalidInviteCode =>
      'That invite code doesn\'t match any household.';

  @override
  String get alreadyInHousehold =>
      'You\'re already in a household. Leave it first to join another.';

  @override
  String get householdFull => 'This household already has 10 members.';

  @override
  String get ok => 'OK';

  @override
  String get documents => 'Documents';

  @override
  String get addDocument => 'Add document';

  @override
  String get documentsHint =>
      'Keep the warranty card, a product photo or the manual here, next to the receipt.';

  @override
  String get noDocuments => 'No documents added.';

  @override
  String get documentReceipt => 'Receipt';

  @override
  String get documentWarrantyCard => 'Warranty card';

  @override
  String get documentProductPhoto => 'Product photo';

  @override
  String get documentManual => 'Manual';

  @override
  String get documentOther => 'Other';

  @override
  String get choosePdf => 'Choose PDF';

  @override
  String get analyticsMine => 'Mine';

  @override
  String get analyticsHousehold => 'Household';

  @override
  String get spendingByYear => 'Spending by year';

  @override
  String get topStores => 'Top stores';

  @override
  String get addWarrantyEndToCalendar => 'Add warranty end to calendar';

  @override
  String get addReturnDeadlineToCalendar => 'Add return deadline to calendar';

  @override
  String calendarWarrantyEnds(Object product) {
    return 'Warranty ends: $product';
  }

  @override
  String calendarReturnDeadline(Object product) {
    return 'Last day to return: $product';
  }

  @override
  String calendarEventDescription(Object product) {
    return 'Added from Sakk for $product.';
  }

  @override
  String get couldNotOpenCalendar => 'Couldn\'t open your calendar app.';

  @override
  String get onboardingFamilyTitle => 'Share with Your Family';

  @override
  String get onboardingFamilyDescription =>
      'Create a household so everyone sees the family\'s warranties, and ask the AI assistant anything about your products.';

  @override
  String get notifExpiringTitle => 'Warranty expiring soon';

  @override
  String notifExpiringBody(Object product) {
    return '$product\'s warranty is ending soon';
  }

  @override
  String notifExpiringInDays(num days, Object product) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$product\'s warranty ends in $_temp0';
  }

  @override
  String get notifExpiredTitle => 'Warranty expired';

  @override
  String notifExpiredBody(Object product) {
    return '$product\'s warranty has expired';
  }

  @override
  String get notifReturnTitle => 'Return window closing';

  @override
  String notifReturnBody(Object product) {
    return 'You have 2 days left to return $product if you need to';
  }

  @override
  String get confirmEmailToFinishSignup =>
      'Check your email and open the confirmation link, then sign in';
}
