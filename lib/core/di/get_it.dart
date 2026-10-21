import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_data_source/auth_data_source.dart';
import '../../features/auth/data/auth_repo_impl/auth_repo_impl.dart';
import '../../features/auth/domain/auth_repo/auth_repo.dart';
import '../../features/auth/domain/usecase/delete_account_usecase.dart';
import '../../features/auth/domain/usecase/get_user_usecase.dart';
import '../../features/auth/domain/usecase/send_password_reset_otp_usecase.dart';
import '../../features/auth/domain/usecase/signin_usecase.dart';
import '../../features/auth/domain/usecase/signin_with_google_usecase.dart';
import '../../features/auth/domain/usecase/signout_usecase.dart';
import '../../features/auth/domain/usecase/signup_usecase.dart';
import '../../features/auth/domain/usecase/update_avatar_usecase.dart';
import '../../features/auth/domain/usecase/update_password_usecase.dart';
import '../../features/auth/domain/usecase/verify_password_reset_otp_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/chat/data/chat_data_source/chat_data_source.dart';
import '../../features/chat/data/chat_repo_impl/chat_repo_impl.dart';
import '../../features/chat/domain/chat_repo/chat_repo.dart';
import '../../features/chat/domain/usecase/send_message_use_case.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/details/presentation/cubit/details_cubit.dart';
import '../../features/forget_password/presentation/cubit/password_reset_cubit.dart';
import '../../features/notification/data/notification_data_source/notification_data_source.dart';
import '../../features/notification/data/notification_repo_impl/notification_repo_impl.dart';
import '../../features/notification/domain/notification_repo/notification_repo.dart';
import '../../features/notification/domain/usecase/add_notification_use_case.dart';
import '../../features/notification/domain/usecase/delete_notification_use_case.dart';
import '../../features/notification/domain/usecase/get_notification_use_case.dart';
import '../../features/notification/domain/usecase/mark_notification_read_use_case.dart';
import '../../features/notification/domain/usecase/watch_added_notifications_use_case.dart';
import '../../features/household/data/household_data_source.dart';
import '../../features/household/data/household_repo.dart';
import '../../features/household/presentation/cubit/household_cubit.dart';
import '../../features/notification/presentation/cubit/notification_cubit.dart';
import '../../features/pro/data/pro_status_data_source.dart';
import '../../features/pro/data/purchases_gateway.dart';
import '../../features/pro/presentation/cubit/paywall_cubit.dart';
import '../../features/pro/presentation/cubit/pro_cubit.dart';
import '../../features/products/data/product_data_source/product_data_source.dart';
import '../../features/products/data/product_data_source/product_local_data_source.dart';
import '../../features/products/data/product_repo_impl/product_repo_impl.dart';
import '../../features/products/domain/product_repo/product_repo.dart';
import '../../features/products/domain/usecase/add_product_usecase.dart';
import '../../features/products/domain/usecase/clear_cached_products_usecase.dart';
import '../../features/products/domain/usecase/delete_product_usecase.dart';
import '../../features/products/domain/usecase/get_products_usecase.dart';
import '../../features/products/domain/usecase/product_extras_usecases.dart';
import '../../features/products/domain/usecase/scan_receipt_usecase.dart';
import '../../features/products/domain/usecase/update_product_usecase.dart';
import '../../features/products/presentation/cubit/product_cubit.dart';
import '../../features/installments/data/installment_data_source/installment_data_source.dart';
import '../../features/installments/data/installment_data_source/installment_local_data_source.dart';
import '../../features/installments/data/installment_repo_impl/installment_repo_impl.dart';
import '../../features/installments/domain/installment_repo/installment_repo.dart';
import '../../features/installments/domain/usecase/add_installment_plan_usecase.dart';
import '../../features/installments/domain/usecase/clear_cached_installments_usecase.dart';
import '../../features/installments/domain/usecase/delete_installment_plan_usecase.dart';
import '../../features/installments/domain/usecase/extract_installment_usecase.dart';
import '../../features/installments/domain/usecase/get_installment_plans_usecase.dart';
import '../../features/installments/domain/usecase/set_payment_paid_usecase.dart';
import '../../features/installments/domain/usecase/update_installment_plan_usecase.dart';
import '../../features/installments/presentation/cubit/installment_form_cubit.dart';
import '../../features/installments/presentation/cubit/installment_smart_add_cubit.dart';
import '../../features/installments/presentation/cubit/installments_cubit.dart';
import '../../features/subscriptions/data/subscription_data_source/subscription_data_source.dart';
import '../../features/subscriptions/data/subscription_data_source/subscription_local_data_source.dart';
import '../../features/subscriptions/data/subscription_repo_impl/subscription_repo_impl.dart';
import '../../features/subscriptions/domain/subscription_repo/subscription_repo.dart';
import '../../features/subscriptions/domain/usecase/add_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecase/clear_cached_subscriptions_usecase.dart';
import '../../features/subscriptions/domain/usecase/delete_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecase/extract_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecase/get_catalog_usecase.dart';
import '../../features/subscriptions/domain/usecase/get_subscriptions_usecase.dart';
import '../../features/subscriptions/domain/usecase/update_renewal_date_usecase.dart';
import '../../features/subscriptions/domain/usecase/update_subscription_usecase.dart';
import '../../features/subscriptions/presentation/cubit/catalog_cubit.dart';
import '../../features/subscriptions/presentation/cubit/smart_add_cubit.dart';
import '../../features/subscriptions/presentation/cubit/subscription_form_cubit.dart';
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../error/network_info.dart';
import '../locale_controller/locale_controller.dart';
import '../logger/app_logger.dart';
import '../logger/console_logger.dart';
import '../service/amount_visibility_controller.dart';
import '../service/biometric_auth_service.dart';
import '../service/home_widget_sync.dart';
import '../service/notification_service.dart';
import '../service/onboarding_service.dart';
import '../service/password_recovery_service.dart';
import '../service/reminder_controller.dart';
import '../service/reminder_settings.dart';
import '../service/receipt_ai_client.dart';
import '../service/review_prompter.dart';
import '../service/storage_service.dart';
import '../service/installment_reminder_service.dart';
import '../service/subscription_reminder_service.dart';
import '../service/storage_service_impl.dart';
import '../service/supabase_client.dart';
import '../service/supabase_client_impl.dart';
import '../service/warranty_notification_service.dart';

import '../theme/theme_controller.dart';
import '../util/notified_warranties_tracker.dart';
import '../util/shared_preferences.dart';


GetIt getIt = GetIt.instance;


void setupLocator() {

  getIt.registerLazySingleton<AppLogger>(() => ConsoleLogger());

  getIt.registerLazySingleton<SupabaseService>(
        () => SupabaseServiceImpl(Supabase.instance.client),
  );

  getIt.registerLazySingleton<StorageService>(
        () => StorageServiceImpl(Supabase.instance.client),
  );

  getIt.registerLazySingleton<InternetConnection>(() => InternetConnection());
  getIt.registerLazySingleton<NetworkInfo>(
        () => NetworkInfoImpl(getIt<InternetConnection>()),
  );
  getIt.registerLazySingleton<AuthDataSource>(
        () => AuthDataSourceImpl(getIt<SupabaseService>(), getIt<StorageService>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepoImpl(getIt<AuthDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );

  getIt.registerLazySingleton<SignInUseCase>(
        () => SignInUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignupUsecase>(
        () => SignupUsecaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOutUseCase>(
        () => SignOutUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerFactory<AuthCubit>(
        () => AuthCubit(
      getIt<SignupUsecase>(),
      getIt<SignInUseCase>(),
      getIt<SignOutUseCase>(),
      getIt<UpdateAvatarUseCase>(),
      getIt<SignInWithGoogleUseCase>(),
      getIt<DeleteAccountUseCase>(),
    ),
  );
  getIt.registerLazySingleton<GetUserUseCase>(
        () => GetUserUseCaseImpl(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<UpdateAvatarUseCase>(
        () => UpdateAvatarUsecaseImpl(getIt<AuthRepository>()),
  );

  // ---- Settings ----
  getIt.registerLazySingleton<ThemeController>(() => ThemeController());
  getIt.registerLazySingleton<ReminderController>(() => ReminderController());
  getIt.registerLazySingleton<ReminderSettings>(() => ReminderSettings());
  getIt.registerLazySingleton<ReviewPrompter>(() => ReviewPrompter());
  getIt.registerLazySingleton<AmountVisibilityController>(() => AmountVisibilityController());
  getIt.registerLazySingleton<HomeWidgetSync>(
        () => HomeWidgetSync(getIt<LocaleController>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<LocaleController>(() => LocaleController());

  // Device-level Face ID / Touch ID / fingerprint gate — see
  // BiometricAuthService's doc comment for how this relates to (and does
  // NOT replace) the Supabase session itself.
  getIt.registerLazySingleton<BiometricAuthService>(
        () => BiometricAuthServiceImpl(),
  );

  // ---- Products ----
  // Shared by receipt scanning and subscription smart add.
  getIt.registerLazySingleton<ReceiptAiClient>(() => ReceiptAiClient(Supabase.instance.client));
  getIt.registerLazySingleton<ProductDataSource>(
        () => ProductDataSourceImpl(Supabase.instance.client, ai: getIt<ReceiptAiClient>()),
  );
  getIt.registerLazySingleton<ProductLocalDataSource>(
        () => ProductLocalDataSourceImpl(getIt<SupabaseService>()),
  );
  getIt.registerLazySingleton<ProductRepo>(
        () => ProductRepoImpl(getIt<ProductDataSource>(), getIt<ProductLocalDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<ScanReceiptUseCase>(
        () => ScanReceiptUseCaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<AddProductUseCase>(
        () => AddProductUseCaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<UpdateProductUseCase>(
        () => UpdateProductUsecaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<DeleteProductUseCase>(
        () => DeleteProductUsecaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<ClearCachedProductsUseCase>(
        () => ClearCachedProductsUseCaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<ProductExtrasUseCase>(
        () => ProductExtrasUseCaseImpl(getIt<ProductRepo>()),
  );
  getIt.registerLazySingleton<GetProductsUseCase>(
        () => GetProductsUseCaseImpl(getIt<ProductRepo>()),
  );

  // ---- Subscriptions ----
  getIt.registerLazySingleton<SubscriptionDataSource>(
        () => SubscriptionDataSourceImpl(Supabase.instance.client, ai: getIt<ReceiptAiClient>()),
  );
  getIt.registerLazySingleton<SubscriptionLocalDataSource>(
        () => SubscriptionLocalDataSourceImpl(getIt<SupabaseService>()),
  );
  getIt.registerLazySingleton<SubscriptionRepo>(
        () => SubscriptionRepoImpl(getIt<SubscriptionDataSource>(), getIt<SubscriptionLocalDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<GetCatalogUseCase>(
        () => GetCatalogUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  getIt.registerLazySingleton<GetSubscriptionsUseCase>(
        () => GetSubscriptionsUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  getIt.registerLazySingleton<AddSubscriptionUseCase>(
        () => AddSubscriptionUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  getIt.registerLazySingleton<UpdateSubscriptionUseCase>(
        () => UpdateSubscriptionUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  getIt.registerLazySingleton<DeleteSubscriptionUseCase>(
        () => DeleteSubscriptionUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  getIt.registerLazySingleton<ExtractSubscriptionUseCase>(
        () => ExtractSubscriptionUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  getIt.registerLazySingleton<ClearCachedSubscriptionsUseCase>(
        () => ClearCachedSubscriptionsUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  // Singleton: the Home card and the Subscriptions screen share its list.
  getIt.registerLazySingleton<UpdateRenewalDateUseCase>(
        () => UpdateRenewalDateUseCaseImpl(getIt<SubscriptionRepo>()),
  );
  getIt.registerLazySingleton<SubscriptionReminderService>(
        () => SubscriptionReminderService(
      getUserUseCase: getIt<GetUserUseCase>(),
      addNotificationUseCase: getIt<AddNotificationUseCase>(),
      tracker: getIt<NotifiedWarrantiesTracker>(),
      localNotifications: getIt<NotificationService>(),
      logger: getIt<AppLogger>(),
      locale: getIt<LocaleController>(),
      settings: getIt<ReminderSettings>(),
    ),
  );
  getIt.registerLazySingleton<SubscriptionsCubit>(
        () => SubscriptionsCubit(
      getIt<GetSubscriptionsUseCase>(),
      updateRenewalDateUseCase: getIt<UpdateRenewalDateUseCase>(),
      reminders: getIt<SubscriptionReminderService>(),
    ),
  );
  getIt.registerFactory<CatalogCubit>(() => CatalogCubit(getIt<GetCatalogUseCase>()));
  getIt.registerFactory<SmartAddCubit>(() => SmartAddCubit(getIt<ExtractSubscriptionUseCase>()));
  getIt.registerFactory<SubscriptionFormCubit>(
        () => SubscriptionFormCubit(
      getIt<AddSubscriptionUseCase>(),
      getIt<UpdateSubscriptionUseCase>(),
      getIt<DeleteSubscriptionUseCase>(),
      getIt<SubscriptionsCubit>(),
    ),
  );

  // ---- Installments ----
  getIt.registerLazySingleton<InstallmentDataSource>(
        () => InstallmentDataSourceImpl(Supabase.instance.client, ai: getIt<ReceiptAiClient>()),
  );
  getIt.registerLazySingleton<InstallmentLocalDataSource>(
        () => InstallmentLocalDataSourceImpl(getIt<SupabaseService>()),
  );
  getIt.registerLazySingleton<InstallmentRepo>(
        () => InstallmentRepoImpl(getIt<InstallmentDataSource>(), getIt<InstallmentLocalDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<GetInstallmentPlansUseCase>(
        () => GetInstallmentPlansUseCaseImpl(getIt<InstallmentRepo>()),
  );
  getIt.registerLazySingleton<AddInstallmentPlanUseCase>(
        () => AddInstallmentPlanUseCaseImpl(getIt<InstallmentRepo>()),
  );
  getIt.registerLazySingleton<UpdateInstallmentPlanUseCase>(
        () => UpdateInstallmentPlanUseCaseImpl(getIt<InstallmentRepo>()),
  );
  getIt.registerLazySingleton<DeleteInstallmentPlanUseCase>(
        () => DeleteInstallmentPlanUseCaseImpl(getIt<InstallmentRepo>()),
  );
  getIt.registerLazySingleton<SetPaymentPaidUseCase>(
        () => SetPaymentPaidUseCaseImpl(getIt<InstallmentRepo>()),
  );
  getIt.registerLazySingleton<ExtractInstallmentUseCase>(
        () => ExtractInstallmentUseCaseImpl(getIt<InstallmentRepo>()),
  );
  getIt.registerFactory<InstallmentSmartAddCubit>(() => InstallmentSmartAddCubit(getIt<ExtractInstallmentUseCase>()));
  getIt.registerLazySingleton<ClearCachedInstallmentsUseCase>(
        () => ClearCachedInstallmentsUseCaseImpl(getIt<InstallmentRepo>()),
  );
  // Singleton: Home, the Installments screens, product details and Analytics share its list.
  getIt.registerLazySingleton<InstallmentReminderService>(
        () => InstallmentReminderService(
      getUserUseCase: getIt<GetUserUseCase>(),
      addNotificationUseCase: getIt<AddNotificationUseCase>(),
      tracker: getIt<NotifiedWarrantiesTracker>(),
      localNotifications: getIt<NotificationService>(),
      logger: getIt<AppLogger>(),
      locale: getIt<LocaleController>(),
      settings: getIt<ReminderSettings>(),
    ),
  );
  getIt.registerLazySingleton<InstallmentsCubit>(
        () => InstallmentsCubit(
      getIt<GetInstallmentPlansUseCase>(),
      getIt<SetPaymentPaidUseCase>(),
      reminders: getIt<InstallmentReminderService>(),
    ),
  );
  getIt.registerFactory<InstallmentFormCubit>(
        () => InstallmentFormCubit(
      getIt<AddInstallmentPlanUseCase>(),
      getIt<UpdateInstallmentPlanUseCase>(),
      getIt<DeleteInstallmentPlanUseCase>(),
      getIt<InstallmentsCubit>(),
    ),
  );

  getIt.registerLazySingleton<SearchHistoryService>(() => SearchHistoryServiceImpl());

  getIt.registerLazySingleton<NotificationService>(() => NotificationService.instance);
  getIt.registerLazySingleton<NotifiedWarrantiesTracker>(
        () => NotifiedWarrantiesTrackerImpl(),
  );
  getIt.registerLazySingleton<NotificationDataSource>(
        () => NotificationDataSourceImpl(supabaseService: getIt<SupabaseService>()),
  );
  getIt.registerLazySingleton<NotificationRepo>(
        () => NotificationRepoImpl(
      getIt<NotificationDataSource>(),
      getIt<NetworkInfo>(),
      getIt<AppLogger>(),
    ),
  );
  getIt.registerLazySingleton<GetNotificationsUseCase>(
        () => GetNotificationUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerLazySingleton<MarkNotificationAsReadUseCase>(
        () => MarkNotificationAsReadUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerLazySingleton<DeleteNotificationUseCase>(
        () => DeleteNotificationUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerLazySingleton<AddNotificationUseCase>(
        () => AddNotificationUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  getIt.registerLazySingleton<WatchAddedNotificationsUseCase>(
        () => WatchAddedNotificationsUseCaseImpl(notificationRepo: getIt<NotificationRepo>()),
  );
  // Singleton: the Home badge and the Notifications screen share its list.
  getIt.registerLazySingleton<NotificationCubit>(
        () => NotificationCubit(
      getNotificationsUseCase: getIt<GetNotificationsUseCase>(),
      markNotificationAsReadUseCase: getIt<MarkNotificationAsReadUseCase>(),
      deleteNotificationUseCase: getIt<DeleteNotificationUseCase>(),
      watchAddedNotificationsUseCase: getIt<WatchAddedNotificationsUseCase>(),
    ),
  );

  getIt.registerLazySingleton<WarrantyNotificationService>(
        () => WarrantyNotificationService(
      getUserUseCase: getIt<GetUserUseCase>(),
      addNotificationUseCase: getIt<AddNotificationUseCase>(),
      tracker: getIt<NotifiedWarrantiesTracker>(),
      localNotifications: getIt<NotificationService>(),
      reminders: getIt<ReminderController>(),
      logger: getIt<AppLogger>(),
      locale: getIt<LocaleController>(),
      settings: getIt<ReminderSettings>(),
    ),
  );

  getIt.registerLazySingleton<HouseholdRepo>(
        () => HouseholdRepo(HouseholdDataSource(Supabase.instance.client), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  // Singleton: Profile manages it, product screens read member names from it.
  getIt.registerLazySingleton<HouseholdCubit>(
        () => HouseholdCubit(getIt<HouseholdRepo>(), getIt<ProductsCubit>()),
  );

  getIt.registerLazySingleton<ProductsCubit>(
        () => ProductsCubit(
      getIt<GetProductsUseCase>(),
      getIt<DeleteProductUseCase>(),
      getIt<SearchHistoryService>(),
      getIt<WarrantyNotificationService>(),
      getIt<HomeWidgetSync>(),
    ),
  );

  getIt.registerFactory<DetailsCubit>(
        () => DetailsCubit(
      updateProductUseCase: getIt<UpdateProductUseCase>(),
      productsCubit: getIt<ProductsCubit>(),
    ),
  );

  // ---- Sakk Pro ----
  // RevenueCat's public SDK keys (not secrets). Without them the app runs
  // on the free plan and the paywall says purchases aren't available.
  getIt.registerLazySingleton<PurchasesGateway>(
        () => RevenueCatGateway(
      androidApiKey: dotenv.env['REVENUECAT_ANDROID_KEY'],
      iosApiKey: dotenv.env['REVENUECAT_IOS_KEY'],
      packageName: 'com.sakk.app',
    ),
  );
  getIt.registerLazySingleton<ProStatusDataSource>(
        () => ProStatusDataSourceImpl(Supabase.instance.client),
  );
  // Singleton: the badge, counters, paywall and add buttons share it.
  getIt.registerLazySingleton<ProCubit>(
        () => ProCubit(
      getIt<ProStatusDataSource>(),
      getIt<PurchasesGateway>(),
      userIdChanges: Supabase.instance.client.auth.onAuthStateChange.map((auth) => auth.session?.user.id),
      logger: getIt<AppLogger>(),
      appResumed: _appResumed(),
    ),
  );
  getIt.registerFactory<PaywallCubit>(
        () => PaywallCubit(getIt<PurchasesGateway>(), getIt<ProCubit>(), getIt<AppLogger>()),
  );

  // ---- Chat ----
  getIt.registerLazySingleton<ChatDataSource>(
        () => ChatDataSourceImpl(Supabase.instance.client),
  );
  getIt.registerLazySingleton<ChatRepo>(
        () => ChatRepoImpl(getIt<ChatDataSource>(), getIt<NetworkInfo>(), getIt<AppLogger>()),
  );
  getIt.registerLazySingleton<SendMessageUseCase>(
        () => SendMessageUseCaseImpl(getIt<ChatRepo>()),
  );
  getIt.registerLazySingleton<GetChatHistoryUseCase>(
        () => GetChatHistoryUseCaseImpl(getIt<ChatRepo>()),
  );


  getIt.registerLazySingleton<ChatCubit>(
        () => ChatCubit(
          getIt<SendMessageUseCase>(),
          Supabase.instance.client.auth.onAuthStateChange.map((auth) => auth.session?.user.id),
          getHistoryUseCase: getIt<GetChatHistoryUseCase>(),
        ),
  );


  // alongside your other AuthCubit/usecase registrations:
  getIt.registerLazySingleton<SendPasswordResetOtpUseCase>(
        () => SendPasswordResetOtpUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<VerifyPasswordResetOtpUseCase>(
        () => VerifyPasswordResetOtpUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<UpdatePasswordUseCase>(
        () => UpdatePasswordUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerFactory<PasswordResetCubit>(
        () => PasswordResetCubit(
      getIt<SendPasswordResetOtpUseCase>(),
      getIt<VerifyPasswordResetOtpUseCase>(),
      getIt<UpdatePasswordUseCase>(),
      getIt<SignOutUseCase>(),
      getIt<PasswordRecoveryService>(),
    ),
  );


  getIt.registerLazySingleton<OnboardingService>(() => OnboardingServiceImpl());
  getIt.registerLazySingleton<PasswordRecoveryService>(() => PasswordRecoveryServiceImpl());

  getIt.registerLazySingleton<SignInWithGoogleUseCase>(
        () => SignInWithGoogleUseCaseImpl(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<DeleteAccountUseCase>(
        () => DeleteAccountUseCaseImpl(getIt<AuthRepository>()),
  );
}


/// Fires each time the app comes back to the foreground. Lives as long as
/// the app (the cubits that listen are app-wide).
Stream<void> _appResumed() {
  final controller = StreamController<void>.broadcast();
  AppLifecycleListener(onResume: () => controller.add(null));
  return controller.stream;
}
