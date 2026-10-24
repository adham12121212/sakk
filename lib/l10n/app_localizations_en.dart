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
  String get emailHint => 'example@gmail.com';

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
  String deleteProductLinkedPlans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count installment plans are linked to this product. They will be kept, without the link.',
      one:
          '1 installment plan is linked to this product. It will be kept, without the link.',
    );
    return '$_temp0';
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
      'This permanently deletes your account and all its data: products, receipts and documents, subscriptions, installment plans, chat history and notifications. This can\'t be undone.';

  @override
  String get deleteAccountProTitle => 'Cancel Sakk Pro first';

  @override
  String get deleteAccountProBody =>
      'Deleting your account doesn\'t cancel your Sakk Pro subscription in Google Play. Cancel it there first so you aren\'t charged again.';

  @override
  String get deleteAccountProContinue => 'Delete anyway';

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

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get subscriptionsMonthlyTotal => 'Monthly total';

  @override
  String subscriptionsYearlyTotal(String amount) {
    return '$amount a year';
  }

  @override
  String subscriptionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscriptions',
      one: '1 subscription',
      zero: 'No subscriptions',
    );
    return '$_temp0';
  }

  @override
  String get noSubscriptionsYet => 'No subscriptions yet';

  @override
  String get noSubscriptionsBody =>
      'Add Netflix, Spotify and the rest to see what you pay each month and get reminded before each renewal.';

  @override
  String get subscriptionsHomeEmpty => 'Track Netflix, Spotify and more';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get editSubscription => 'Edit subscription';

  @override
  String get customSubscription => 'Custom subscription';

  @override
  String get customSubscriptionHint => 'Not in the list? Enter it yourself';

  @override
  String get searchServicesHint => 'Search services';

  @override
  String get noServicesFound => 'No services match your search';

  @override
  String get choosePlan => 'Choose a plan';

  @override
  String get otherPlan => 'Other plan';

  @override
  String get otherPlanHint => 'Enter the price yourself';

  @override
  String fromPrice(String amount) {
    return 'From $amount';
  }

  @override
  String get subscriptionName => 'Name';

  @override
  String get subscriptionNameRequired => 'Enter a name';

  @override
  String get planNameOptional => 'Plan (optional)';

  @override
  String get priceRequired => 'Enter the price';

  @override
  String get currency => 'Currency';

  @override
  String get billingCycle => 'Billing cycle';

  @override
  String get billingMonthly => 'Monthly';

  @override
  String get billingYearly => 'Yearly';

  @override
  String pricePerMonth(String amount) {
    return '$amount / month';
  }

  @override
  String pricePerYear(String amount) {
    return '$amount / year';
  }

  @override
  String get nextRenewal => 'Next renewal';

  @override
  String get paymentMethodOptional => 'Payment method (optional)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get renewsToday => 'Renews today';

  @override
  String get renewsTomorrow => 'Renews tomorrow';

  @override
  String renewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Renews in $days days',
      one: 'Renews in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get renewalPassed => 'Renewal date passed';

  @override
  String get subscriptionSaved => 'Subscription saved';

  @override
  String get subscriptionDeleted => 'Subscription deleted';

  @override
  String get deleteSubscriptionQuestion => 'Delete subscription?';

  @override
  String deleteSubscriptionBody(String name) {
    return '$name and its reminders will be removed.';
  }

  @override
  String get currencyEgp => 'EGP';

  @override
  String get subscriptionCategoryStreaming => 'Streaming';

  @override
  String get subscriptionCategoryMusic => 'Music';

  @override
  String get subscriptionCategoryGaming => 'Gaming';

  @override
  String get subscriptionCategoryCloud => 'Cloud storage';

  @override
  String get subscriptionCategoryProductivity => 'Productivity';

  @override
  String get subscriptionCategoryAi => 'AI';

  @override
  String get subscriptionCategoryDelivery => 'Delivery';

  @override
  String get subscriptionCategoryTelecom => 'Telecom & internet';

  @override
  String get subscriptionCategoryOther => 'Other';

  @override
  String get smartAdd => 'Smart add';

  @override
  String get smartAddHint => 'From a screenshot or a bank SMS';

  @override
  String get smartAddTakePhoto => 'Take a photo';

  @override
  String get smartAddChooseScreenshot => 'Choose a screenshot';

  @override
  String get smartAddPasteText => 'Paste an SMS or email';

  @override
  String get smartAddPasteTitle => 'Paste the message';

  @override
  String get smartAddPasteHint => 'For example, the bank SMS for the charge';

  @override
  String get smartAddPasteFromClipboard => 'Paste';

  @override
  String get smartAddPasteEmpty => 'Paste the message first';

  @override
  String get smartAddRead => 'Read';

  @override
  String get smartAddReading => 'Reading…';

  @override
  String get smartAddPrivacyNote =>
      'Full card numbers and email addresses are removed before the text is read.';

  @override
  String get subscriptionScanUnreadable =>
      'We couldn\'t find a subscription in that. Try a clearer screenshot or the full message, or add it manually.';

  @override
  String get notifRenewalTitle => 'Subscription renewing soon';

  @override
  String notifRenewalBody(
    int days,
    String daysText,
    String name,
    String price,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$name renews in $daysText days for $price',
      one: '$name renews tomorrow for $price',
      zero: '$name renews today for $price',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsAnalyticsTitle => 'Subscriptions';

  @override
  String get subscriptionsAnalyticsEmpty =>
      'No subscriptions yet. Tap to add Netflix, Spotify and more.';

  @override
  String get notifRenewedTitle => 'Subscription renewed';

  @override
  String notifRenewedBody(
    int days,
    String daysText,
    String name,
    String price,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$name renewed $daysText days ago for $price. Check you were charged the right amount.',
      one:
          '$name renewed yesterday for $price. Check you were charged the right amount.',
    );
    return '$_temp0';
  }

  @override
  String get account => 'Account';

  @override
  String get accountActionsHint => 'Log out or delete your account';

  @override
  String get installments => 'Installments';

  @override
  String get addInstallment => 'Add installment';

  @override
  String get editInstallment => 'Edit installment plan';

  @override
  String get installmentsLeftToPay => 'Left to pay';

  @override
  String get installmentsHomeEmpty => 'Track Valu, bank and store installments';

  @override
  String get noInstallmentsYet => 'No installments yet';

  @override
  String get noInstallmentsBody =>
      'Add what you\'re paying off with Valu, your bank or a store to see what\'s left and get reminded before each due date.';

  @override
  String installmentsActiveCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText active plans',
      one: '1 active plan',
      zero: 'No active plans',
    );
    return '$_temp0';
  }

  @override
  String installmentsDueThisMonth(String amount) {
    return '$amount due this month';
  }

  @override
  String installmentsOverdueTotal(String amount) {
    return '$amount overdue';
  }

  @override
  String installmentsOverdueBanner(int count, String countText, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText installments are overdue ($amount)',
      one: '1 installment is overdue ($amount)',
    );
    return '$_temp0';
  }

  @override
  String installmentsPaidOf(String paid, String total) {
    return '$paid of $total paid';
  }

  @override
  String get installmentDueToday => 'Due today';

  @override
  String get installmentDueTomorrow => 'Due tomorrow';

  @override
  String installmentDueInDays(int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $daysText days',
      one: 'Due in 1 day',
    );
    return '$_temp0';
  }

  @override
  String installmentOverdueBy(int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Overdue by $daysText days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0';
  }

  @override
  String get installmentPaidOff => 'Paid off';

  @override
  String get installmentCancelled => 'Cancelled';

  @override
  String installmentOfTotal(String amount) {
    return 'of $amount';
  }

  @override
  String get nextInstallment => 'Next installment';

  @override
  String nextInstallmentDue(String amount, String when) {
    return 'Next $amount · $when';
  }

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String get markUnpaid => 'Mark as unpaid';

  @override
  String get markUnpaidQuestion => 'Mark as unpaid?';

  @override
  String markUnpaidBody(String date) {
    return 'The installment due $date will show as unpaid again.';
  }

  @override
  String get installmentMarkedPaid => 'Marked as paid';

  @override
  String paidOn(String date) {
    return 'Paid $date';
  }

  @override
  String get paymentSchedule => 'Payment schedule';

  @override
  String get linkedProduct => 'Product';

  @override
  String get installmentProvider => 'Provider';

  @override
  String get installmentProviderOptional => 'Provider (optional)';

  @override
  String get providerBank => 'Bank';

  @override
  String get providerStore => 'Store';

  @override
  String get downPayment => 'Down payment';

  @override
  String get downPaymentOptional => 'Down payment (optional)';

  @override
  String get downPaymentTooHigh => 'More than the total price';

  @override
  String get interestOrFees => 'Interest or fees';

  @override
  String get interestOrFeesOptional => 'Interest / fees (optional)';

  @override
  String get installmentAmount => 'Installments';

  @override
  String installmentsTimesAmount(String count, String amount) {
    return '$count × $amount';
  }

  @override
  String get installmentAmountPerMonth => 'Monthly installment';

  @override
  String get installmentAmountAuto =>
      'Worked out from the total, down payment and fees.';

  @override
  String get installmentAmountCustom => 'Your own amount.';

  @override
  String get useEvenSplit => 'Split evenly';

  @override
  String get nothingLeftToFinance => 'The down payment covers the whole price';

  @override
  String get installmentsCountLabel => 'Number of installments';

  @override
  String get installmentsCountInvalid => 'Enter a whole number from 1 to 360';

  @override
  String installmentsCountBelowPaid(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $countText: that many are already paid',
      one: 'At least 1: one is already paid',
    );
    return '$_temp0';
  }

  @override
  String get installmentsCountBelowPaidGeneric =>
      'The number of installments can\'t be less than those already paid.';

  @override
  String monthsCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get firstInstallmentDate => 'First installment';

  @override
  String get dueDayOfMonth => 'Due day';

  @override
  String dueDayValue(String day) {
    return 'Day $day of each month';
  }

  @override
  String get dueDayShortMonthsHint =>
      'In shorter months it\'s due on the last day.';

  @override
  String get installmentFor => 'What are you paying for?';

  @override
  String get installmentForProduct => 'One of my products';

  @override
  String get installmentForOther => 'Something else';

  @override
  String get installmentTitle => 'What did you buy?';

  @override
  String get installmentTitleRequired => 'Enter what you bought';

  @override
  String get chooseProduct => 'Choose a product';

  @override
  String get chooseProductRequired =>
      'Choose a product, or pick \"Something else\"';

  @override
  String get searchProducts => 'Search your products';

  @override
  String get noProductsMatch => 'No products match.';

  @override
  String get noProductsToLink =>
      'You have no products yet. Add one first, or pick \"Something else\".';

  @override
  String editPaidInstallmentsNote(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countText installments are already paid and stay as they are. Changes apply to the rest.',
      one:
          '1 installment is already paid and stays as it is. Changes apply to the rest.',
    );
    return '$_temp0';
  }

  @override
  String get schedulePreview => 'Schedule preview';

  @override
  String get schedulePreviewEmpty =>
      'Enter the total price and number of installments to see the schedule.';

  @override
  String schedulePreviewSummary(
    int count,
    String countText,
    String total,
    String lastDate,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText installments · $total in total · last on $lastDate',
      one: '1 installment · $total in total · last on $lastDate',
    );
    return '$_temp0';
  }

  @override
  String showAllInstallments(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show all $countText',
    );
    return '$_temp0';
  }

  @override
  String get showLess => 'Show less';

  @override
  String get installmentSaved => 'Installment plan saved';

  @override
  String get installmentDeleted => 'Installment plan deleted';

  @override
  String get deleteInstallmentQuestion => 'Delete installment plan?';

  @override
  String deleteInstallmentBody(String name) {
    return '$name, its payment schedule and reminders will be removed.';
  }

  @override
  String get cancelInstallmentPlan => 'Cancel plan';

  @override
  String get reactivateInstallmentPlan => 'Make active again';

  @override
  String get installmentPlanCancelled => 'Plan cancelled';

  @override
  String get installmentPlanReactivated => 'Plan active again';

  @override
  String get installmentNotFound => 'Plan not found';

  @override
  String get installmentNotFoundBody => 'It may have been deleted.';

  @override
  String get productInstallmentsHint =>
      'Paying for this in installments? Track what\'s left and get reminded before each due date.';

  @override
  String get notifInstallmentDueSoonTitle => 'Installment due soon';

  @override
  String get notifInstallmentDueTodayTitle => 'Installment due today';

  @override
  String notifInstallmentDueBody(
    int days,
    String daysText,
    String name,
    String price,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$name: $price is due in $daysText days',
      one: '$name: $price is due tomorrow',
      zero: '$name: $price is due today',
    );
    return '$_temp0';
  }

  @override
  String get smartAddChoosePdf => 'Choose a PDF (e.g. the contract)';

  @override
  String get smartAddInstallmentHint =>
      'Fill this in from a contract, screenshot or SMS';

  @override
  String get smartAddInstallmentReview =>
      'Check every field before saving: nothing is saved until you tap the button below.';

  @override
  String get installmentScanUnreadable =>
      'We couldn\'t find an installment plan in that. Try a clearer screenshot, the contract\'s first page or the full message, or fill it in yourself.';

  @override
  String get installmentsThisMonth => 'Due this month';

  @override
  String get installmentsDuePerMonth => 'Due each month';

  @override
  String get installmentsAnalyticsEmpty =>
      'No installments yet. Tap to add what you pay off monthly.';

  @override
  String installmentsChartCurrencyNote(String currency) {
    return 'The chart shows $currency installments only';
  }

  @override
  String get reminders => 'Reminders';

  @override
  String get remindersIntro =>
      'Choose which reminders Sakk sends on this phone.';

  @override
  String get remindersAllOff => 'All off';

  @override
  String get listSeparator => ', ';

  @override
  String get reminderWarranties => 'Warranties';

  @override
  String get reminderWarrantiesHint =>
      'Before a warranty ends, when it ends, and before a return window closes';

  @override
  String get reminderSubscriptionsHint => 'Around each renewal';

  @override
  String get reminderInstallmentsHint => 'Before each installment is due';

  @override
  String get reminderThreeDaysBefore => '3 days before';

  @override
  String get reminderDayBefore => 'The day before';

  @override
  String get reminderDayAfterCheckCharge =>
      'The day after, to check the charge';

  @override
  String get reminderOnDueDay => 'On the due day';

  @override
  String get limitReachedProducts =>
      'You\'ve reached the free plan\'s product limit. Upgrade to Sakk Pro to add more.';

  @override
  String get limitReachedSubscriptions =>
      'You\'ve reached the free plan\'s subscription limit. Upgrade to Sakk Pro to track more.';

  @override
  String get limitReachedInstallments =>
      'The free plan tracks one running installment plan. Upgrade to Sakk Pro to add more.';

  @override
  String get limitReachedScan =>
      'You\'ve used today\'s free scans. Upgrade to Sakk Pro for unlimited scans, or try again tomorrow.';

  @override
  String get limitReachedChat =>
      'You\'ve used today\'s free messages. Upgrade to Sakk Pro, or come back tomorrow.';

  @override
  String get limitReachedFairUse =>
      'You\'ve reached today\'s limit. Please try again tomorrow.';

  @override
  String get chatBusy =>
      'The assistant is busy right now. Please try again in a minute.';

  @override
  String get scanNeedsInternet =>
      'Scanning needs an internet connection. You can still enter the details yourself.';

  @override
  String get chatNeedsInternet => 'The assistant needs an internet connection.';

  @override
  String scansLeftToday(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText scans left today',
      one: '1 scan left today',
      zero: 'No free scans left today',
    );
    return '$_temp0';
  }

  @override
  String chatMessagesLeftToday(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText messages left today',
      one: '1 message left today',
      zero: 'No free messages left today',
    );
    return '$_temp0';
  }

  @override
  String get planBadgeFree => 'Free';

  @override
  String get planBadgePro => 'Sakk Pro';

  @override
  String get planBadgeYearly => 'Pro ⭐ Yearly';

  @override
  String get planBadgeTrial => 'Pro – Trial';

  @override
  String planBadgeTrialDaysLeft(int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysText days left',
      one: '1 day left',
      zero: 'ends today',
    );
    return '$_temp0';
  }

  @override
  String get planBadgeBillingIssue => 'Payment issue';

  @override
  String get sakkPro => 'Sakk Pro';

  @override
  String get proCardFreeBody =>
      'Unlimited products, subscriptions and installments, unlimited AI, and your monthly summary.';

  @override
  String proCardRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String proCardEndsOn(String date) {
    return 'Pro ends on $date. Your data stays.';
  }

  @override
  String proCardTrialEndsOn(String date) {
    return 'Free trial ends on $date';
  }

  @override
  String get proCardBillingIssueBody =>
      'Google Play couldn\'t charge your payment method. Update it to keep Pro.';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get updatePaymentMethod => 'Update payment method';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoreSuccess => 'Sakk Pro restored';

  @override
  String get restoreNothing =>
      'No Sakk Pro purchase found for this Google account';

  @override
  String get paywallHeadlineUpgrade => 'Get more out of Sakk';

  @override
  String get paywallHeadlineScan => 'You\'ve used today\'s free scans';

  @override
  String get paywallHeadlineChat => 'You\'ve used today\'s free messages';

  @override
  String get paywallHeadlineProducts => 'Your free plan is full';

  @override
  String get paywallHeadlineSubscriptions => 'Track all your subscriptions';

  @override
  String get paywallHeadlineInstallments => 'Track all your installments';

  @override
  String get paywallHeadlineSummary => 'See what you\'ll pay this month';

  @override
  String get paywallSubtitle =>
      'No limits on products, subscriptions, installments or AI, plus smart reminders and your monthly summary.';

  @override
  String get paywallFeature => 'Feature';

  @override
  String get paywallFree => 'Free';

  @override
  String get paywallPro => 'Pro';

  @override
  String get featureProducts => 'Warranty products';

  @override
  String get featureSubscriptions => 'Tracked subscriptions';

  @override
  String get featureInstallments => 'Installments';

  @override
  String get featureScans => 'AI scans';

  @override
  String get featureChat => 'AI chat messages';

  @override
  String get featureReminders => 'Reminders';

  @override
  String get featureSummary => 'Monthly summary';

  @override
  String valuePerDay(String countText) {
    return '$countText/day';
  }

  @override
  String get valueUnlimited => 'Unlimited';

  @override
  String get valueBasic => 'Basic';

  @override
  String get valueSmart => 'Smart';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String get bestValue => 'Best value';

  @override
  String savePercent(String percent) {
    return 'Save ~$percent%';
  }

  @override
  String freeTrialDays(int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysText-day free trial',
      one: '1-day free trial',
    );
    return '$_temp0';
  }

  @override
  String get startFreeTrial => 'Start free trial';

  @override
  String get subscribe => 'Subscribe';

  @override
  String autoRenewTrialDisclosure(String days, String price) {
    return 'Free for $days days, then $price. Cancel before the trial ends and you won\'t be charged.';
  }

  @override
  String get autoRenewDisclosure =>
      'Payment is charged to your Google Play account. The subscription renews automatically at the price shown unless you cancel at least 24 hours before the current period ends. Manage or cancel anytime in Google Play → Payments & subscriptions.';

  @override
  String get purchaseSuccess => 'Welcome to Sakk Pro!';

  @override
  String get purchaseFailed =>
      'The purchase didn\'t go through. Please try again.';

  @override
  String get purchasesUnavailable =>
      'Subscriptions aren\'t available right now. Please try again later.';

  @override
  String get proComingSoonIos =>
      'Sakk Pro is coming soon on iPhone. You can keep using the free plan until then.';

  @override
  String get alreadyPro => 'You\'re on Sakk Pro';

  @override
  String get monthlySummary => 'This month';

  @override
  String get monthlySummaryTotal => 'Left to pay this month';

  @override
  String get monthlySummaryTotalHint =>
      'Subscription renewals and unpaid installments from today to the end of the month, overdue ones included.';

  @override
  String get monthlySummaryUpcoming => 'Upcoming payments';

  @override
  String get monthlySummaryNothingDue => 'Nothing left to pay this month.';

  @override
  String get monthlySummaryWarranties => 'Warranties ending soon';

  @override
  String get monthlySummaryNoWarranties =>
      'No warranties end in the next 60 days.';

  @override
  String get monthlySummaryOverdue => 'Overdue';

  @override
  String get summaryRenewal => 'Renewal';

  @override
  String get summaryInstallment => 'Installment';

  @override
  String get reminderCustomTitle => 'Earlier reminder';

  @override
  String get reminderCustomHint => 'One more reminder, this many days before';

  @override
  String get reminderCustomOff => 'Off';

  @override
  String reminderCustomDays(int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysText days',
    );
    return '$_temp0';
  }

  @override
  String get reminderCustomProOnly => 'Sakk Pro';

  @override
  String get paywallHeadlinePdfReport => 'Get everything in one PDF';

  @override
  String get featurePdfReport => 'PDF report';

  @override
  String get proStatusLoadFailed =>
      'Couldn\'t load your plan. Check your connection and try again.';

  @override
  String get pdfReportExport => 'Export PDF report';

  @override
  String get pdfReportFailed =>
      'Couldn\'t create the report. Please try again.';

  @override
  String get pdfReportTitle => 'Sakk report';

  @override
  String pdfReportGenerated(String date) {
    return 'Created on $date';
  }

  @override
  String get pdfReportSummary => 'Summary';

  @override
  String get pdfReportNone => 'None yet';

  @override
  String pdfReportPage(String page, String total) {
    return 'Page $page of $total';
  }

  @override
  String get pdfColNextDue => 'Next payment';

  @override
  String get pdfColPaid => 'Paid';

  @override
  String get pdfColRemaining => 'Remaining';

  @override
  String get pdfColPlan => 'Plan';

  @override
  String get pdfColStatus => 'Status';

  @override
  String get pdfRemainingInstallments => 'Installments left to pay';

  @override
  String get addByVoice => 'Add by voice';

  @override
  String get voiceTitle => 'Tell Sakk what you bought';

  @override
  String get voiceExample =>
      'For example: \"I bought a Samsung 55-inch TV from B.TECH today for 20,000, with a 2-year warranty.\"';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceDone => 'Done';

  @override
  String get voiceMicDenied =>
      'Sakk needs the microphone to add by voice. Allow it in your phone\'s settings.';

  @override
  String get voiceRecordFailed => 'Couldn\'t record. Please try again.';

  @override
  String get voiceUnheard =>
      'We couldn\'t make out a product. Try again and say the product, the store, the price and the warranty.';

  @override
  String get voiceNeedsInternet =>
      'Adding by voice needs an internet connection.';

  @override
  String get voiceYouSaid => 'You said';

  @override
  String get paywallHeadlineVoice => 'Add products just by saying them';

  @override
  String get featureVoice => 'Add by voice';

  @override
  String get limitReachedVoice => 'Add by voice is part of Sakk Pro.';

  @override
  String get voiceUnheardTitle => 'We didn\'t catch that';

  @override
  String get addPhoto => 'Add a photo (optional)';

  @override
  String get addPhotoHint => 'The receipt, the box or the product';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get myPapers => 'My papers';

  @override
  String get papersHomeEmpty => 'Your ID, passport and licences';

  @override
  String get addPaper => 'Add paper';

  @override
  String get editPaper => 'Edit paper';

  @override
  String get noPapersYet => 'No papers yet';

  @override
  String get noPapersBody =>
      'Save your ID, passport, licences and insurance cards with a photo and the expiry date. Sakk reminds you a month before each one expires.';

  @override
  String get papersPrivacyNote =>
      'Your papers are private to your account: they aren\'t shared with your household, other users can\'t open them, and they\'re never sent to the AI.';

  @override
  String get paperNationalId => 'National ID';

  @override
  String get paperPassport => 'Passport';

  @override
  String get paperDrivingLicence => 'Driving licence';

  @override
  String get paperCarLicence => 'Car licence';

  @override
  String get paperCarInsurance => 'Car insurance';

  @override
  String get paperHealthInsurance => 'Medical insurance';

  @override
  String get paperRentalContract => 'Rental contract';

  @override
  String get paperOther => 'Other';

  @override
  String get paperType => 'Type';

  @override
  String get paperName => 'Name';

  @override
  String get paperNameOptional => 'Name (optional)';

  @override
  String get paperViewPhoto => 'View photo';

  @override
  String get paperNameRequired => 'Enter a name for this paper';

  @override
  String get paperNumberOptional => 'Number (optional)';

  @override
  String get paperExpiryDate => 'Expiry date';

  @override
  String get paperPickDate => 'Pick a date';

  @override
  String get paperNoExpiry => 'Doesn\'t expire';

  @override
  String get paperPhotos => 'Photos (optional)';

  @override
  String get paperFront => 'Front';

  @override
  String get paperBack => 'Back';

  @override
  String get paperRemovePhoto => 'Remove photo';

  @override
  String get paperSaved => 'Paper saved';

  @override
  String get paperDeleted => 'Paper deleted';

  @override
  String get deletePaperQuestion => 'Delete paper?';

  @override
  String deletePaperBody(String name) {
    return '$name and its photos will be deleted.';
  }

  @override
  String get paperExpiresToday => 'Expires today';

  @override
  String paperExpiresInDays(int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expires in $daysText days',
      one: 'Expires tomorrow',
    );
    return '$_temp0';
  }

  @override
  String paperValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String paperExpiredOn(String date) {
    return 'Expired on $date';
  }

  @override
  String get paperNoExpiryDate => 'No expiry date';

  @override
  String get paperStatusValid => 'Valid';

  @override
  String get paperStatusExpiringSoon => 'Expiring soon';

  @override
  String get paperStatusExpired => 'Expired';

  @override
  String get paperNumber => 'Number';

  @override
  String get copyPaperNumber => 'Copy number';

  @override
  String get paperNumberCopied => 'Number copied';

  @override
  String get paperNoPhotos => 'No photos. Tap Edit to add the front and back.';

  @override
  String get notifPaperExpiringTitle => 'Paper expiring soon';

  @override
  String get notifPaperExpiredTitle => 'Paper expired';

  @override
  String notifPaperExpiringBody(int days, String daysText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$name expires in $daysText days. Time to renew it.',
      one: '$name expires tomorrow. Time to renew it.',
    );
    return '$_temp0';
  }

  @override
  String notifPaperExpiresTodayBody(String name) {
    return '$name expires today.';
  }

  @override
  String notifPaperExpiredBody(String name) {
    return '$name has expired. Renew it as soon as you can.';
  }

  @override
  String get reminderPapersHint => 'Before each paper expires';

  @override
  String get reminderMonthBefore => 'A month before';

  @override
  String get reminderWeekBefore => 'A week before';

  @override
  String get reminderOnExpiryDay => 'On the expiry day';

  @override
  String get featurePapers => 'Papers';

  @override
  String get paywallHeadlinePapers => 'Keep all your papers in one place';

  @override
  String get limitReachedPapers =>
      'You\'ve reached the free plan\'s paper limit. Upgrade to Sakk Pro to add more.';

  @override
  String get statProducts => 'Products';

  @override
  String get statActive => 'Active';

  @override
  String get statExpiring => 'Expiring';

  @override
  String get statExpired => 'Expired';

  @override
  String get moneyThisMonth => 'Money this month';

  @override
  String get subscriptionPlan => 'Plan';

  @override
  String get subscriptionPaymentMethod => 'Payment method';

  @override
  String subscriptionMonthlyEquivalent(String amount) {
    return 'That\'s $amount a month';
  }

  @override
  String get papersNeedRenewing => 'Needs renewing';

  @override
  String get profile => 'Profile';

  @override
  String papersToRenewCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText need renewing',
      one: '1 needs renewing',
    );
    return '$_temp0';
  }

  @override
  String get papersAllUpToDate => 'All up to date';

  @override
  String papersCountLabel(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText papers',
      one: '1 paper',
    );
    return '$_temp0';
  }

  @override
  String get scanCameraHint =>
      'Point the camera at the receipt or warranty card';

  @override
  String get scanOtherWays => 'Other ways to add';

  @override
  String get scanGalleryHint => 'A photo you already have';

  @override
  String get scanPdfHint => 'An invoice a store emailed you';

  @override
  String get scanVoiceHint => 'Say what you bought and we fill it in';

  @override
  String get scanManualHint => 'No receipt? Type the details in';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodThisYear => 'This year';

  @override
  String get periodAllTime => 'All time';

  @override
  String get analyticsMoney => 'Money';

  @override
  String get installmentSectionDetails => 'Details';

  @override
  String get installmentSectionPrice => 'Price';

  @override
  String get installmentSectionPayments => 'Payments';

  @override
  String get analyticsEmptyTitle => 'No stats yet';

  @override
  String get analyticsEmptyMessage =>
      'Add your first product to see your spending, warranties and categories here.';

  @override
  String analyticsProductsCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String analyticsAverage(String amount) {
    return 'avg $amount';
  }

  @override
  String analyticsShowAllCategories(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show all $countText',
    );
    return '$_temp0';
  }
}
